import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identificadorController = TextEditingController();
  final _senhaController = TextEditingController();

  bool carregando = false;
  bool mostrarSenha = false;

  Future<void> fazerLogin() async {
    final identificador = _identificadorController.text.trim();
    if (identificador.isEmpty || _senhaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o NIF/e-mail e a senha.'),
        ),
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      final email = identificador.contains('@')
          ? identificador
          : '$identificador@login.senai-ponto.app';
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _senhaController.text,
      );
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Não foi possível realizar o login.';

      if (e.code == 'invalid-credential') {
        mensagem = 'E-mail ou senha incorretos.';
      } else if (e.code == 'user-not-found') {
        mensagem = 'Usuário não encontrado.';
      } else if (e.code == 'wrong-password') {
        mensagem = 'Senha incorreta.';
      } else if (e.code == 'invalid-email') {
        mensagem = 'Digite um e-mail válido ou um NIF cadastrado.';
      } else if (e.code == 'too-many-requests') {
        mensagem = 'Muitas tentativas. Aguarde e tente novamente.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _identificadorController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 84,
                  width: 84,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Icon(
                    Icons.access_time_filled_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'SENAI Ponto',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF102A43),
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Seu registro de jornada, com segurança e localização.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF52606D), fontSize: 15),
                ),
                const SizedBox(height: 36),
                TextField(
                  controller: _identificadorController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'NIF ou e-mail',
                    hintText: 'Digite seu NIF ou e-mail cadastrado',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _senhaController,
                  obscureText: !mostrarSenha,
                  onSubmitted: (_) => fazerLogin(),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    hintText: 'Digite sua senha',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: mostrarSenha ? 'Ocultar senha' : 'Mostrar senha',
                      icon: Icon(
                        mostrarSenha
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => mostrarSenha = !mostrarSenha),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: carregando ? null : fazerLogin,
                    child: carregando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'ENTRAR',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 17,
                      color: Color(0xFF087E8B),
                    ),
                    SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'A biometria do aparelho confirma cada registro.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF52606D),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}