import 'package:flutter/material.dart';

class CnpjNotFoundDialog extends StatelessWidget {
  const CnpjNotFoundDialog({
    super.key,
    required this.onSearchAgain,
    required this.onContinue,
  });

  final VoidCallback onSearchAgain;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'CNPJ não encontrado',
        style: theme.textTheme.titleLarge,
      ),
      content: Text(
        'O CNPJ informado não foi localizado na base de dados. Deseja buscar outro ou continuar com preenchimento manual?',
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onSearchAgain();
          },
          child: const Text('Buscar novo CNPJ'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onContinue();
          },
          child: const Text('Continuar mesmo assim'),
        ),
      ],
    );
  }
}
