import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/user.dart';
import '../provider/auth_provider.dart';
import '../utils/const.dart';

/// Manage application users (admin-only). Non-admin users see a read-only
/// list and cannot add/delete. Previously this screen was an empty
/// `Placeholder()`.
class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    final users = auth.users;
    final isAdmin = currentUser?.isAdmin ?? false;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: secondaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Users (${users.length})',
                      style: Theme.of(context).textTheme.titleMedium),
                  if (isAdmin)
                    ElevatedButton.icon(
                      onPressed: () => _showUserDialog(context),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add User'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (users.isEmpty)
                const Center(child: Text('No users yet'))
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final u = users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: u.isAdmin ? primaryColor : primary2Color,
                          child: Text(u.displayName.isNotEmpty
                              ? u.displayName[0].toUpperCase()
                              : '?'),
                        ),
                        title: Text(u.displayName),
                        subtitle: Text('@${u.username} · ${u.role.toUpperCase()}'),
                        trailing: isAdmin
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Edit',
                                    icon: const Icon(Icons.edit, color: Colors.white),
                                    onPressed: () => _showUserDialog(context, existing: u),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: u.id == currentUser?.id
                                        ? null
                                        : () async {
                                            final ok = await auth.deleteUser(u.id);
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(ok
                                                  ? 'User deleted'
                                                  : 'Cannot delete the last admin')),
                                            );
                                          },
                                  ),
                                ],
                              )
                            : null,
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              if (!isAdmin)
                const Text(
                  'Only administrators can add or remove users.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserDialog(BuildContext context, {User? existing}) {
    showDialog(
      context: context,
      builder: (_) => _UserDialog(existing: existing),
    );
  }
}

class _UserDialog extends StatefulWidget {
  final User? existing;
  const _UserDialog({this.existing});

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtl = TextEditingController(text: widget.existing?.displayName);
  late final _usernameCtl = TextEditingController(text: widget.existing?.username);
  final _pinCtl = TextEditingController();
  late UserRole _role;

  @override
  void initState() {
    super.initState();
    _role = widget.existing?.roleEnum ?? UserRole.cashier;
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _usernameCtl.dispose();
    _pinCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (widget.existing == null) {
      final created = await auth.addUser(
        username: _usernameCtl.text,
        pin: _pinCtl.text,
        displayName: _nameCtl.text,
        role: _role,
      );
      if (!mounted) return;
      if (created == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username already exists')),
        );
        return;
      }
    } else {
      await auth.updateUser(
        widget.existing!.id,
        displayName: _nameCtl.text,
        pin: _pinCtl.text.isNotEmpty ? _pinCtl.text : null,
        role: _role,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      backgroundColor: secondaryColor,
      title: Text(isEdit ? 'Edit User' : 'Add User'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(labelText: 'Display Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _usernameCtl,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _pinCtl,
                decoration: InputDecoration(
                  labelText: isEdit ? 'New PIN (leave blank to keep)' : 'PIN',
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                validator: (v) {
                  if (!isEdit && (v == null || v.isEmpty)) return 'Required';
                  if (v != null && v.isNotEmpty && !RegExp(r'^[0-9]{4,8}$').hasMatch(v)) {
                    return '4-8 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UserRole>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: UserRole.values
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _role = v ?? UserRole.staff),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
