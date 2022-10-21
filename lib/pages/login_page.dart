import 'package:flutter/material.dart';
import 'package:wallet/utils/helperfunctions.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:slider_button/slider_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      clientMeta: const PeerMeta(
          name: 'Wallet',
          description: 'An app for converting pictures to NFT',
          url: 'https://walletconnect.org',
          icons: [
            'https://files.gitbook.com/v0/b/gitbook-legacy-files/o/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'
          ]
      )
  );

  var _session, _uri, _signature;

  loginUsingMetamask(BuildContext context) async {
    if (!connector.connected) {
      try {
        var session = await connector.createSession(onDisplayUri: (uri) async {
          _uri = uri;
          await launchUrlString(uri, mode: LaunchMode.externalApplication);
        });
        setState(() {
          _session = session;
        });
      } catch (exp) {
        print(exp);
      }
    }
  }

  signMessageWithMetamask(BuildContext context, String message) async {
    if (connector.connected) {
      try {
        print("Message received");
        print(message);

        EthereumWalletConnectProvider provider =
        EthereumWalletConnectProvider(connector);
        launchUrlString(_uri, mode: LaunchMode.externalApplication);
        var signature = await provider.personalSign(
            message: message, address: _session.accounts[0], password: "");
        print(signature);
        setState(() {
          _signature = signature;
        });
      } catch (exp) {
        print("Error while signing transaction");
        print(exp);
      }
    }
  }

  getNetworkName(chainId) {
    switch (chainId) {
      case 1:
        return 'Ethereum Mainnet';
      case 3:
        return 'Ropsten Testnet';
      case 4:
        return 'Rinkeby Testnet';
      case 5:
        return 'Goreli Testnet';
      case 42:
        return 'Kovan Testnet';
      case 137:
        return 'Polygon Mainnet';
      case 80001:
        return 'Mumbai Testnet';
      default:
        return 'Unknown Chain';
    }
  }

  @override
  Widget build(BuildContext context) {
    connector.on(
        'connect',
            (session) => setState(
              () {
            _session = _session;
          },
        ));
    connector.on(
        'session_update',
            (payload) => setState(() {
          _session = payload;
        }));
    connector.on(
        'disconnect',
            (payload) => setState(() {
            _session = null;
          }
        )
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Page'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/main_page_image.png',
              fit: BoxFit.fitHeight,
            ),
            (_session != null) ?
            Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${_session.accounts[0]}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20,),
                      Row(
                        children: [
                          const Text(
                            'Chain: ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            getNetworkName(_session.chainId),
                            style: const TextStyle(fontSize: 16),
                          )
                        ],
                      ),
                      (_session.chainId != 80001)
                          ? Row(
                        children: const [
                          Icon(Icons.warning,
                              color: Colors.redAccent, size: 15),
                          Text('Network not supported. Switch to '),
                          Text(
                            'Mumbai Testnet',
                            style:
                            TextStyle(fontWeight: FontWeight.bold),
                          )
                        ],
                      ):
                      Container(
                        alignment: Alignment.center,
                        child: (_signature == null)
                            ? Container(
                          alignment: Alignment.center,
                          child: ElevatedButton(
                              onPressed: () =>
                                  signMessageWithMetamask(
                                      context,
                                      generateSessionMessage(
                                          _session.accounts[0])),
                              child: const Text('Sign Message')),
                        )
                            : Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "Signature: ",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Text(
                                    truncateString(
                                        _signature.toString(), 4, 2),
                                    style: const TextStyle(
                                        fontSize: 16)
                                )
                              ],
                            ),
                            const SizedBox(height: 20),
                            SliderButton(
                              action: () async {

                              },
                              label: const Text('Slide to login'),
                              icon: const Icon(Icons.check),
                            )
                          ],
                        ),
                      )
                    ]
                )
            ):
            ElevatedButton(
                onPressed: () => {
                  loginUsingMetamask(context)},
                child: const Text("Connect with Metamask")
            )
          ],
        ),
      ),
    );
  }
}