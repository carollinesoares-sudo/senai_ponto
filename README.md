# SENAI Ponto

Aplicativo Flutter de registro de ponto com autenticação Firebase, confirmação
biométrica do aparelho, validação de geolocalização em um raio de 100 metros e
histórico sincronizado em tempo real com Cloud Firestore.

## Entregáveis

- **Aplicativo mobile:** login por e-mail ou NIF, validação biométrica antes do
  registro, conferência de distância e lista dos 20 registros mais recentes.
- **Relatório de implementação:** veja [Relatório de implementação](#relatório-de-implementação).
- **Instalação e uso:** veja [Instalação e uso](#instalação-e-uso).

## Relatório de implementação

### Fluxo do aplicativo

1. A pessoa entra com e-mail/senha do Firebase Authentication. Para login por
   NIF, o app converte o identificador para
   `NIF@login.senai-ponto.app`; a conta correspondente precisa existir no
   Firebase Authentication com esse e-mail e a senha cadastrada.
2. No botão **Bater ponto**, o Android solicita confirmação biométrica do
   aparelho (rosto, impressão digital ou outra biometria compatível).
3. O app verifica serviço e permissão de localização, obtém a posição atual e
   calcula a distância em metros até as coordenadas configuradas do local.
4. O registro só é enviado se a distância for menor ou igual a 100 m.
5. Os registros ficam em `users/{uid}/attendance` no Firestore e o histórico
   acompanha as atualizações em tempo real.

### Organização do código

- `lib/screens/login_screen.dart`: formulário e autenticação.
- `lib/screens/home_screen.dart`: confirmação biométrica, tela de ponto e
  histórico ao vivo.
- `lib/services/location_service.dart`: permissões, GPS e cálculo da distância.
- `lib/services/attendance_service.dart`: criação e leitura dos registros.
- `lib/config/workplace_config.dart`: nome, coordenadas do local e raio.
- `lib/main.dart`: inicialização do Firebase e roteamento pela sessão.

### Dados de cada registro

Cada documento contém `userId`, `email`, `timestamp` (horário do servidor),
`latitude`, `longitude`, `distanceMeters` e `withinAllowedRadius`. Os dados são
vinculados ao usuário autenticado. O app não captura nem armazena imagem facial:
a biometria é processada pelo sistema operacional do aparelho.

### Critérios atendidos

- **Competência técnica (40%):** Flutter, Firebase Authentication, Cloud
  Firestore, geolocalização e biometria local.
- **Interface e usabilidade (20%):** telas responsivas, feedback de erros,
  estados de carregamento, histórico e mensagens em português.
- **Criatividade e solução de problemas (20%):** bloqueio fora do raio,
  biometria antes de registrar, tratamento de permissão/GPS indisponível e
  validação de configuração do local.
- **Documentação (20%):** instruções de configuração, execução, uso e regras de
  segurança abaixo.

## Instalação e uso

### Pré-requisitos

- Flutter/Dart compatíveis com o `pubspec.yaml`.
- Android Studio ou dispositivo Android com GPS e biometria configurada.
- Projeto Firebase com **Authentication (E-mail/senha)** e **Cloud Firestore**
  habilitados.

### Configuração

1. Abra `lib/config/workplace_config.dart` e defina latitude e longitude reais
   do local de trabalho. O app bloqueia registros até que coordenadas válidas
   sejam configuradas. O limite está definido em `radiusMeters` (100 m).
2. Configure Firebase para Android com o mesmo identificador de aplicativo do
   projeto. Gere `lib/firebase_options.dart` com FlutterFire CLI e coloque o
   `google-services.json` correspondente em `android/app/`.
3. No Firebase Authentication, habilite o provedor **E-mail/senha** e crie as
   contas dos funcionários. Para login com NIF, use como e-mail da conta
   `<NIF>@login.senai-ponto.app`; para login com e-mail, use o e-mail real da
   conta. A senha é a senha definida no Firebase.
4. Crie o banco Cloud Firestore e publique as regras abaixo.
5. Na pasta `senai_ponto`, execute:

   ```powershell
   flutter pub get
   flutter run
   ```

### Regras recomendadas do Cloud Firestore

Publique as regras no console Firebase (Firestore Database → Regras):

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/attendance/{recordId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null
        && request.auth.uid == userId
        && request.resource.data.userId == userId
        && request.resource.data.withinAllowedRadius == true
        && request.resource.data.distanceMeters is number
        && request.resource.data.distanceMeters <= 100;
      allow update, delete: if false;
    }
  }
}
```

As regras são necessárias: a verificação feita no app não substitui controles
de acesso no servidor. Para uso institucional, considere validar distância,
integridade do aparelho e horário também em um serviço confiável no backend.

### Uso

1. Faça login.
2. Habilite localização e biometria no Android e conceda a permissão de GPS.
3. Toque em **Bater ponto** e confirme a biometria.
4. Se estiver até 100 m do local configurado, o registro é salvo e aparece no
   histórico. Se estiver fora do raio ou houver erro de permissão/GPS, o app
   informa o motivo e não salva o ponto.
5. Use o ícone de saída no topo para encerrar a sessão.

### Execução dos testes

```powershell
flutter test
flutter analyze
```

## Limitações conhecidas

- As coordenadas do estabelecimento devem ser configuradas antes da execução;
  o projeto não presume o endereço do SENAI do aluno.
- O login por NIF usa um endereço sintético associado à conta Firebase, pois
  Firebase Authentication recebe e-mail/senha neste fluxo.
- A biometria depende de hardware, cadastro local e suporte do Android; o app
  não realiza reconhecimento facial próprio.
- Os registros são transmitidos ao Firestore quando há conexão com a internet.
