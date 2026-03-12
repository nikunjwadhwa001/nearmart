import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum CacheReadSource {
  memory,
  disk,
}

class QueryCacheStats {
  // Hits served from in-memory map (fastest path).
  final int memoryHits;
  // Hits served from disk (SharedPreferences) after memory miss.
  final int diskHits;
  // No usable cache entry found within requested freshness window.
  final int misses;
  // Fresh network fetches performed after cache miss/expiry.
  final int networkFetches;
  // Network failed, stale cached value returned instead.
  final int staleFallbacks;
  // Fetch failures where no stale fallback was returned.
  final int fetchErrors;
  // Cache write operations.
  final int writes;
  // Key/prefix invalidation operations.
  final int invalidations;
  // Full cache clear operations.
  final int clears;

  const QueryCacheStats({
    required this.memoryHits,
    required this.diskHits,
    required this.misses,
    required this.networkFetches,
    required this.staleFallbacks,
    required this.fetchErrors,
    required this.writes,
    required this.invalidations,
    required this.clears,
  });

  int get totalHits => memoryHits + diskHits;

  int get totalReads => totalHits + misses;

  // 0.0 - 1.0 cache hit ratio across read attempts.
  double get hitRate => totalReads == 0 ? 0.0 : totalHits / totalReads;

  Map<String, int> toMap() {
    return {
      'memoryHits': memoryHits,
      'diskHits': diskHits,
      'misses': misses,
      'networkFetches': networkFetches,
      'staleFallbacks': staleFallbacks,
      'fetchErrors': fetchErrors,
      'writes': writes,
      'invalidations': invalidations,
      'clears': clears,
      'totalHits': totalHits,
      'totalReads': totalReads,
      // Keep percentage in integer form for compact log readability.
      'hitRatePercent': (hitRate * 100).round(),
    };
  }
}

// Lightweight query cache used by repositories.
// - Memory map serves hot reads while app is running.
// - SharedPreferences persists cached payloads across app restarts.
class QueryCache {
  QueryCache._();

  static final QueryCache instance = QueryCache._();

  static const _prefix = 'query_cache:';

  final Map<String, _CacheRecord> _memory = {};

  int _memoryHits = 0;
  int _diskHits = 0;
  int _misses = 0;
  int _networkFetches = 0;
  int _staleFallbacks = 0;
  int _fetchErrors = 0;
  int _writes = 0;
  int _invalidations = 0;
  int _clears = 0;

  // Snapshot of current counters for logging/inspection.
  QueryCacheStats get stats => QueryCacheStats(
    memoryHits: _memoryHits,
    diskHits: _diskHits,
    misses: _misses,
    networkFetches: _networkFetches,
    staleFallbacks: _staleFallbacks,
    fetchErrors: _fetchErrors,
    writes: _writes,
    invalidations: _invalidations,
    clears: _clears,
  );

  // Useful between manual test sessions to measure a specific flow.
  void resetStats() {
    _memoryHits = 0;
    _diskHits = 0;
    _misses = 0;
    _networkFetches = 0;
    _staleFallbacks = 0;
    _fetchErrors = 0;
    _writes = 0;
    _invalidations = 0;
    _clears = 0;
  }

  // Cache-first read with network fallback.
  // If fresh cache exists: return immediately.
  // If fetch fails and staleOnError=true: return last stale value.
  Future<T> getOrFetch<T>({
    required String key,
    required Duration ttl,
    required Future<T> Function() fetcher,
    required T Function(Object? raw) decode,
    Object? Function(T value)? encode,
    bool staleOnError = true,
  }) async {
    // 1) Try fresh cache within ttl window.
    final fresh = await _readRaw(key, maxAge: ttl);
    if (fresh != null) {
      if (fresh.source == CacheReadSource.memory) {
        _memoryHits++;
      } else {
        _diskHits++;
      }
      return decode(fresh.data);
    }

    _misses++;

    try {
      // 2) Fresh fetch if cache miss/expired.
      final fresh = await fetcher();
      _networkFetches++;
      await setRaw(key, encode != null ? encode(fresh) : fresh);
      return fresh;
    } catch (_) {
      _fetchErrors++;
      // 3) Network failed: optionally return stale cache for resilience.
      if (staleOnError) {
        final stale = await _readRaw(key);
        if (stale != null) {
          _staleFallbacks++;
          return decode(stale.data);
        }
      }
      rethrow;
    }
  }

  // Reads a raw cached payload.
  // maxAge=null means "allow stale" (used by stale-on-error path).
  Future<Object?> getRaw(String key, {Duration? maxAge}) async {
    final value = await _readRaw(key, maxAge: maxAge);
    return value?.data;
  }

  Future<_CacheValue?> _readRaw(String key, {Duration? maxAge}) async {
    final memory = _memory[key];
    if (memory != null) {
      if (!_isExpired(memory.savedAtMs, maxAge)) {
        return _CacheValue(data: memory.data, source: CacheReadSource.memory);
      }
      if (maxAge == null) {
        return _CacheValue(data: memory.data, source: CacheReadSource.memory);
      }
    }

    // Memory miss: read persisted cache.
    final prefs = await SharedPreferences.getInstance();
    final rawString = prefs.getString(_prefKey(key));
    if (rawString == null) return null;

    try {
      final parsed = jsonDecode(rawString) as Map<String, dynamic>;
      final savedAtMs = parsed['savedAtMs'] as int?;
      final data = parsed['data'];
      if (savedAtMs == null) return null;

      // Backfill memory cache to speed up subsequent reads.
      _memory[key] = _CacheRecord(savedAtMs: savedAtMs, data: data);

      if (_isExpired(savedAtMs, maxAge) && maxAge != null) {
        return null;
      }

      return _CacheValue(data: data, source: CacheReadSource.disk);
    } catch (_) {
      // Corrupted payload: remove it to avoid repeated decode failures.
      await prefs.remove(_prefKey(key));
      _memory.remove(key);
      return null;
    }
  }

  // Writes cache to both memory and disk.
  Future<void> setRaw(String key, Object? data) async {
    final savedAtMs = DateTime.now().millisecondsSinceEpoch;
    final payload = {
      'savedAtMs': savedAtMs,
      'data': data,
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey(key), jsonEncode(payload));
    _memory[key] = _CacheRecord(savedAtMs: savedAtMs, data: data);
    _writes++;
  }

  Future<void> invalidate(String key) async {
    _memory.remove(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey(key));
    _invalidations++;
  }

  // Invalidates every entry that starts with a logical prefix.
  // Useful when one mutation affects many related cache keys.
  Future<void> invalidatePrefix(String keyPrefix) async {
    _memory.removeWhere((key, _) => key.startsWith(keyPrefix));

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_prefix + keyPrefix)) {
        await prefs.remove(key);
      }
    }
    _invalidations++;
  }

  // Clears all query-cache entries.
  // Called on logout/delete to avoid leaking one user's cached data to another.
  Future<void> clearAll() async {
    _memory.clear();

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_prefix)) {
        await prefs.remove(key);
      }
    }
    _clears++;
  }

  bool _isExpired(int savedAtMs, Duration? maxAge) {
    if (maxAge == null) return false;
    final age = DateTime.now().millisecondsSinceEpoch - savedAtMs;
    return age > maxAge.inMilliseconds;
  }

  String _prefKey(String key) => '$_prefix$key';
}

class _CacheRecord {
  final int savedAtMs;
  final Object? data;

  const _CacheRecord({
    required this.savedAtMs,
    required this.data,
  });
}

class _CacheValue {
  final Object? data;
  final CacheReadSource source;

  const _CacheValue({
    required this.data,
    required this.source,
  });
}
