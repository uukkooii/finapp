import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/account_provider.dart';

class AccountManagePage extends StatelessWidget {
  const AccountManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ap = Provider.of<AccountProvider>(context);

    return Scaffold(
      backgroundColor: context.themeBg,
      appBar: AppBar(
        title: const Text('账户管理', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        backgroundColor: context.themeBg,
        foregroundColor: context.themeText,
        elevation: 0,
      ),
      body: ap.accounts.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💳', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('还没有账户', style: TextStyle(color: context.themeSub, fontSize: 15)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: ap.accounts.length,
              itemBuilder: (ctx, i) {
                final name = ap.accounts[i];
                return Card(
                  color: context.themeCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_wallet, color: goldColor),
                    title: Text(name, style: TextStyle(color: context.themeText, fontWeight: FontWeight.w500)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: context.themeHint, size: 20),
                          onPressed: () => _showRenameDialog(context, ap, name),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: expenseRed, size: 20),
                          onPressed: () => _confirmDelete(context, ap, name),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ap),
        backgroundColor: goldColor,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('添加账户'),
      ),
    );
  }

  void _showAddDialog(BuildContext context, AccountProvider ap) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeCard,
        title: Text('添加账户', style: TextStyle(color: context.themeText)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: context.themeText),
          decoration: InputDecoration(
            hintText: '如：招商银行、公积金',
            hintStyle: TextStyle(color: context.themeHint),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: goldColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: goldColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消', style: TextStyle(color: context.themeSub)),
          ),
          TextButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                ap.add(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('添加', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, AccountProvider ap, String oldName) {
    final ctrl = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeCard,
        title: Text('重命名', style: TextStyle(color: context.themeText)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: context.themeText),
          decoration: InputDecoration(
            hintText: '新名称',
            hintStyle: TextStyle(color: context.themeHint),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: goldColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: goldColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消', style: TextStyle(color: context.themeSub)),
          ),
          TextButton(
            onPressed: () {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty && newName != oldName) {
                ap.rename(oldName, newName);
                Navigator.pop(ctx);
              }
            },
            child: const Text('保存', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AccountProvider ap, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeCard,
        title: Text('删除账户', style: TextStyle(color: context.themeText)),
        content: Text('确定删除「$name」？\n该账户下的交易记录不会被删除。', style: TextStyle(color: context.themeText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消', style: TextStyle(color: context.themeSub)),
          ),
          TextButton(
            onPressed: () {
              ap.delete(name);
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: expenseRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
