# GeoUnião

GeoUnião é um aplicativo móvel desenvolvido em Flutter como trabalho acadêmico para aprendizado prático sobre desenvolvimento mobile e integração com APIs nativas do Android. O app permite tirar fotos geolocalizadas, adicionar descrições e nomes às imagens, visualizar as fotos em um mapa e compartilhar relatórios contendo a foto, descrição e localização via WhatsApp ou SMS.

---

## Funcionalidades

- Captura de fotos usando a câmera do dispositivo.
- Registro automático da localização (latitude e longitude) no momento da foto.
- Adição de nome e descrição para cada foto capturada.
- Visualização das fotos em uma grade na tela inicial.
- Visualização detalhada da foto com informações e opções para excluir ou ver no mapa.
- Compartilhamento do relatório da foto (imagem, descrição e localização) via WhatsApp ou SMS.
- Solicitação de permissões de câmera e localização ao usuário.
- Interface moderna e responsiva, com navegação intuitiva.

---

## Tecnologias e APIs Nativas Utilizadas

O aplicativo é desenvolvido em Flutter e utiliza as seguintes APIs nativas do Android por meio de plugins:

- **Câmera (Camera API):** Para captura de fotos usando a câmera do dispositivo, via plugin `camera`.
- **Localização (Location API):** Para obter a geolocalização atual do dispositivo no momento da foto, via plugin `geolocator`.
- **Compartilhamento (Intent API):** Para compartilhar imagens e textos com outros aplicativos, especialmente WhatsApp e SMS, via plugin `share_plus` e, opcionalmente, `android_intent_plus` para intents nativas.
- **Permissões (Runtime Permissions):** Solicitação dinâmica das permissões de câmera e localização ao usuário, via plugin `permission_handler`.

---

## Estrutura do Projeto

- `lib/screens/`: Contém as telas principais do app, como a tela inicial, detalhes da foto e mapa.
- `lib/models/`: Modelos de dados usados no app, como o modelo da foto.
- `assets/`: Imagens e ícones usados na interface.
- `android/`: Configurações específicas do Android, incluindo permissões e configurações do build.

---

## Configurações Importantes

- **Permissões Android:** Declaradas no `AndroidManifest.xml` para câmera, localização e acesso à internet.
- **Solicitação de Permissões em Tempo de Execução:** Implementada para garantir que o app só acesse câmera e localização após autorização do usuário.
- **Compatibilidade:** Testado em dispositivos Android modernos; pode ser adaptado para iOS com ajustes mínimos.

---

## Equipe

- [Leandro Andrekowicz](https://github.com/LeandroAndrekowicz)  
- [Luciana Miechotek](https://github.com/LMiechotek)  
- [Marcelo Santos](https://github.com/MarceloSantos1906)  

---

## Observações

Este projeto foi desenvolvido como parte de um trabalho de faculdade com o objetivo de aprender sobre desenvolvimento mobile multiplataforma com Flutter e integração com APIs nativas do Android. O código é aberto para estudo e aprimoramento.