import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_state.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../models/address.dart';
import '../providers/address_provider.dart';

/// Shows a bottom sheet for address selection.
/// Returns the selected Address, or null if cancelled.
Future<Address?> showAddressSelectionSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<Address>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _AddressSelectionSheet(),
  );
}

class _AddressSelectionSheet extends ConsumerStatefulWidget {
  const _AddressSelectionSheet();

  @override
  ConsumerState<_AddressSelectionSheet> createState() =>
      _AddressSelectionSheetState();
}

class _AddressSelectionSheetState
    extends ConsumerState<_AddressSelectionSheet> {
  bool _showAddForm = false;
  String? _selectedAddressId;
  String? _deletingAddressId;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _addressLineCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _label = 'Home';

  // Location data (auto-filled)
  bool _isLocating = false;
  String? _detectedArea;
  String? _detectedCity;
  String? _detectedPincode;
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _addressLineCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  /// Get current location and reverse geocode it.
  Future<void> _detectLocation() async {
    setState(() => _isLocating = true);

    try {
      // Check location service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          showAppInfoSnackBar(context, 'Please enable location services');
        }
        setState(() => _isLocating = false);
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            showAppInfoSnackBar(context, 'Location permission denied');
          }
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          showAppErrorSnackBar(
            context,
            'Location permission permanently denied. Enable in Settings.',
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      // Reverse geocode
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _detectedArea = [
            place.subLocality,
            place.locality != place.subLocality ? place.thoroughfare : null,
          ].where((s) => s != null && s.isNotEmpty).join(', ');
          _detectedCity = place.locality;
          _detectedPincode = place.postalCode;
        });
      }
    } catch (e) {
      if (mounted) {
        showAppErrorSnackBar(context, 'Could not detect location: $e');
      }
    }

    if (mounted) setState(() => _isLocating = false);
  }

  @override
  Widget build(BuildContext context) {
    final addressesAsync = ref.watch(myAddressesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _showAddForm ? 'Add Address' : 'Deliver to',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (!_showAddForm)
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _showAddForm = true);
                        _detectLocation();
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add New'),
                    ),
                  if (_showAddForm)
                    TextButton(
                      onPressed: () => setState(() => _showAddForm = false),
                      child: const Text('Cancel'),
                    ),
                ],
              ),
            ),

            const Divider(),

            // Content
            Expanded(
              child: _showAddForm
                  ? _buildAddForm(scrollController)
                  : _buildAddressList(addressesAsync, scrollController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList(
    AsyncValue<List<Address>> addressesAsync,
    ScrollController scrollController,
  ) {
    return addressesAsync.when(
      loading: () => const AppLoadingState(),
      error: (e, _) => AppErrorState(
        title: 'Unable to load addresses',
        message: 'Please check your internet connection\nand try again',
        action: AppRetryButton(
          onPressed: () => ref.invalidate(myAddressesProvider),
          label: 'Retry',
          icon: Icons.refresh,
        ),
      ),
      data: (addresses) {
        if (addresses.isEmpty) {
          // No addresses — show add form directly
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_showAddForm) {
              setState(() => _showAddForm = true);
              _detectLocation();
            }
          });
          return const AppEmptyState(
            icon: Icons.location_on_outlined,
            title: 'No saved addresses',
            message: 'Add one to continue.',
            iconSize: 52,
            padding: EdgeInsets.all(24),
          );
        }

        final selectedId = _resolveSelectedAddressId(addresses);

        final selectedAddress = addresses.firstWhere(
          (address) => address.id == selectedId,
        );

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: addresses.length,
                itemBuilder: (context, index) {
                  final address = addresses[index];
                  return _AddressTile(
                    address: address,
                    selected: address.id == selectedId,
                    isDeleting: _deletingAddressId == address.id,
                    onTap: () {
                      setState(() => _selectedAddressId = address.id);
                    },
                    onDelete: () => _deleteAddress(address),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, selectedAddress),
                    child: const Text('Confirm & Deliver Here'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAddress(Address address) async {
    if (_deletingAddressId != null) return;

    final shouldDelete = await showAppConfirmDialog(
      context,
      title: 'Delete Address',
      message: 'Remove this saved address? This cannot be undone.',
      confirmText: 'Delete',
      confirmColor: AppTheme.error,
    );

    if (!shouldDelete) return;

    setState(() => _deletingAddressId = address.id);

    try {
      final repo = ref.read(addressRepositoryProvider);
      await repo.deleteAddress(address.id);

      ref.invalidate(myAddressesProvider);

      if (!mounted) return;

      if (_selectedAddressId == address.id) {
        setState(() => _selectedAddressId = null);
      }

      showAppSuccessSnackBar(context, 'Address deleted.');
    } catch (e) {
      if (mounted) {
        showAppErrorSnackBar(context, 'Failed to delete address: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _deletingAddressId = null);
      }
    }
  }

  String _resolveSelectedAddressId(List<Address> addresses) {
    if (_selectedAddressId != null &&
        addresses.any((address) => address.id == _selectedAddressId)) {
      return _selectedAddressId!;
    }

    final defaultAddress = addresses.where((address) => address.isDefault);
    if (defaultAddress.isNotEmpty) {
      return defaultAddress.first.id;
    }

    return addresses.first.id;
  }

  Widget _buildAddForm(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Location auto-detect section ──
            if (_isLocating)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Detecting your location...',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else if (_detectedArea != null || _detectedCity != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.my_location,
                          color: AppTheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Detected Location',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppTheme.primary,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _detectLocation,
                          child: const Text(
                            'Refresh',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_detectedArea != null && _detectedArea!.isNotEmpty)
                      Text(
                        _detectedArea!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    if (_detectedCity != null || _detectedPincode != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          [_detectedCity, _detectedPincode]
                              .where((s) => s != null && s.isNotEmpty)
                              .join(' — '),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              // No location yet — show detect button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _detectLocation,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Use Current Location'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // ── Address line (mandatory) ──
            TextFormField(
              controller: _addressLineCtrl,
              decoration: const InputDecoration(
                labelText: 'House / Flat No, Street *',
                hintText: 'e.g. 42-B, Sector 22, Near Gurudwara',
                prefixIcon: Icon(Icons.edit_location_alt_outlined),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              validator: AppFormValidators.requiredAddressLine,
            ),

            const SizedBox(height: 16),

            // ── Phone number ──
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                hintText: '10-digit mobile number',
                prefixIcon: Icon(Icons.phone_outlined),
                prefixText: '+91 ',
              ),
              keyboardType: TextInputType.phone,
              maxLength: 10,
              validator: AppFormValidators.requiredIndianMobile,
            ),

            const SizedBox(height: 16),

            // ── Label (Home / Work / Other) ──
            const Text(
              'Save as',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['Home', 'Work', 'Other'].map((label) {
                final isSelected = _label == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                    onSelected: (_) => setState(() => _label = label),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAndSelect,
                child: const Text('Save Address'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAndSelect() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final repo = ref.read(addressRepositoryProvider);
      final address = await repo.addAddress(
        addressLine: _addressLineCtrl.text.trim(),
        label: _label,
        city: _detectedCity,
        pincode: _detectedPincode,
        latitude: _latitude,
        longitude: _longitude,
        phone: '+91${_phoneCtrl.text.trim()}',
        isDefault: true,
      );

      // Invalidate cache so future reads pick up the new address
      ref.invalidate(myAddressesProvider);

      if (!mounted) return;

      setState(() {
        _selectedAddressId = address.id;
        _showAddForm = false;
      });

      showAppSuccessSnackBar(context, 'Address saved. Confirm to place order.');
    } catch (e) {
      if (mounted) {
        showAppErrorSnackBar(context, 'Failed to save address: $e');
      }
    }
  }
}

class _AddressTile extends StatelessWidget {
  final Address address;
  final bool selected;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _AddressTile({
    required this.address,
    required this.selected,
    required this.isDeleting,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.75)
                : address.isDefault
                    ? AppTheme.primary.withValues(alpha: 0.4)
                    : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              address.label == 'Work'
                  ? Icons.work_outline
                  : address.label == 'Other'
                      ? Icons.place_outlined
                      : Icons.home_outlined,
              color: AppTheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'DEFAULT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.shortDisplay,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (address.phone != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      address.phone!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDeleting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    color: AppTheme.error,
                    tooltip: 'Delete address',
                    splashRadius: 20,
                  ),
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? AppTheme.primary : AppTheme.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
