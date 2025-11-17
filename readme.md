# App TCC – Flutter  
Interface móvel para cadastro e notificações

Este repositório contém o **aplicativo móvel em Flutter**, utilizado para cadastro de usuários e recebimento de notificações push integradas ao backend de reconhecimento facial.

> ⚠ Este README assume que você já possui o **backend rodando** e acessível na rede local (por exemplo, `http://192.168.1.10:5000`).

---

## 📑 Sumário

- [📂 Requisitos](#-requisitos)
- [📥 Clonando o Repositório](#-clonando-o-repositório)
- [🪟 Configuração no Windows](#-configuração-no-windows)
- [🐧 Configuração no Linux](#-configuração-no-linux)
- [🍏 Configuração no macOS](#-configuração-no-macos)
- [🌐 Configurando o IP do Backend](#-configurando-o-ip-do-backend)
- [▶️ Executando o Aplicativo](#️-executando-o-aplicativo)

---

# 📂 Requisitos

Antes de iniciar, garanta que os seguintes softwares estejam instalados:

### Requisitos gerais (todos os sistemas)
- **Git**
- **Flutter SDK** (configurado no PATH, com `flutter doctor` sem erros críticos)
- **Android Studio** (para SDK, emululador e ferramentas Android) ou:
  - Dispositivo Android físico com **modo desenvolvedor** e **depuração USB**
- **Conta no Firebase**:
  - Projeto criado
  - Configuração do **Firebase Cloud Messaging (FCM)**
  - Arquivo `google-services.json` configurado no projeto

---

# 📥 Clonando o Repositório

```bash
git clone https://github.com/ToxicOtter/app_tcc.git
cd app_tcc
flutter pub get
```

---

# 🪟 Configuração no Windows

1. Verifique a instalação do Flutter:
   ```cmd
   flutter doctor
   ```

2. Instale/configure o Android Studio e crie um emulador.

3. Baixe dependências:
   ```cmd
   flutter pub get
   ```

4. Configure o IP do backend (ver seção abaixo).

5. Rodar o app:
   ```cmd
   flutter run
   ```

---

# 🐧 Configuração no Linux

1. Dependências básicas:
   ```bash
   sudo apt update
   sudo apt install git curl unzip xz-utils
   ```

2. Verificar ambiente Flutter:
   ```bash
   flutter doctor
   ```

3. Instalar Android Studio e configurar SDK/emulador.

4. Baixar dependências:
   ```bash
   flutter pub get
   ```

5. Rodar o app:
   ```bash
   flutter run
   ```

---

# 🍏 Configuração no macOS

1. Verificar instalação:
   ```bash
   flutter doctor
   ```

2. Instalar Android Studio e/ou Xcode.

3. Baixar dependências:
   ```bash
   flutter pub get
   ```

4. Rodar:
   ```bash
   flutter run
   ```

---

# 🌐 Configurando o IP do Backend

## 1. Descubra o IP da máquina onde o backend está rodando

- Windows:
  ```cmd
  ipconfig
  ```

- Linux:
  ```bash
  ip addr | grep "inet " | grep -v 127.0.0.1
  ```

- macOS:
  ```bash
  ifconfig | grep "inet " | grep -v 127.0.0.1
  ```

Exemplo de IP obtido:  
```
192.168.1.10
```

---

## 2. Configure o IP no código Flutter

Abra:

```
lib/lib/screens/phone_input_screen.dart
lib/main.dart
```

Edite:

```dart
late final SessionService _session = SessionService('http://SEU_IP_LOCAL:5001'); //main.dart
final String base = 'http://SEU_IP_LOCAL:5001'; //phone_input_screen.dart
```

Exemplo:

```dart
late final SessionService _session = SessionService('http://192.168.1.10:5001'); //main.dart
final String base = 'http://192.168.1.10:5001'; //phone_input_screen.dart
```

---

# ▶️ Executando o Aplicativo

Com tudo configurado:

```bash
flutter run
```

O app será compilado e iniciado no dispositivo ou emulador.