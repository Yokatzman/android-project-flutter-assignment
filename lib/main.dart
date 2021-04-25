import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart'; // Add this line.
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hello_me/AuthRepository.dart';
import 'package:hello_me/FavoritesRepository.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'package:hello_me/GrabbingWidget.dart';
import 'package:hello_me/HomeBottom.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  firebase_storage.FirebaseStorage _storage =
      firebase_storage.FirebaseStorage.instance;
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthRepository.instance()),
        ChangeNotifierProxyProvider<AuthRepository, FavoritesRepository>(
            create: (_) => FavoritesRepository(),
            update: (_, auth, favorites) => favorites!..updateFavorites(auth))
      ],
      child: MaterialApp(
        title: 'Startup Name Generator',
        theme: ThemeData(
          // Add the 3 lines from here...
          primaryColor: Colors.red,
        ),
        home: RandomWords(_storage),
      ),
    );
  }
}

class RandomWords extends StatefulWidget {
  firebase_storage.FirebaseStorage _storage;
  RandomWords(this._storage);
  @override
  _RandomWordsState createState() => _RandomWordsState(_storage);
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = generateWordPairs().take(10).toList(); // NEW
  final _biggerFont = const TextStyle(fontSize: 18); // NEW
  final snapController = new SnappingSheetController();
  firebase_storage.FirebaseStorage _storage;
  _RandomWordsState(this._storage);
  @override
  Widget build(BuildContext context) {
    List<SnappingPosition> snappingPositions = [
      SnappingPosition.factor(
        positionFactor: 0.0,
        snappingCurve: Curves.easeOutExpo,
        snappingDuration: Duration(seconds: 1),
        grabbingContentOffset: GrabbingContentOffset.top,
      ),
      SnappingPosition.factor(
        snappingCurve: Curves.elasticOut,
        snappingDuration: Duration(milliseconds: 1750),
        positionFactor: 0.3,
      ),
    ];
    return Consumer<AuthRepository>(
        builder: (context, auth, _) => Scaffold(
              // Add from here...
              appBar: AppBar(
                title: Text('Startup Name Generator'),
                actions: [
                  IconButton(
                      icon: Icon(Icons.exit_to_app),
                      onPressed: auth.status == Status.Authenticated
                          ? () {
                              auth.signOut();
                            }
                          : null),
                  IconButton(icon: Icon(Icons.favorite), onPressed: _pushSaved),
                  IconButton(
                      icon: Icon(Icons.login),
                      onPressed: auth.status != Status.Authenticated
                          ? _pushLogin
                          : null)
                ],
              ),
              //body: _buildSuggestions(),
              body: auth.status == Status.Authenticated
                  ? SnappingSheet(
                      controller: snapController,
                      lockOverflowDrag: true,
                      snappingPositions: snappingPositions,
                      child: _buildSuggestions(),
                      grabbing: InkWell(child: GrabbingWidget(auth.user!.email!),
                      onTap: (){
                        setState(() {
                          snapController.currentSnappingPosition==snappingPositions[0]? snapController.snapToPosition(snappingPositions[1]):
                              snapController.snapToPosition(snappingPositions[0]);
                        });
                      },),
                      grabbingHeight: 75,
                      sheetBelow: SnappingSheetContent(
                        sizeBehavior: SheetSizeStatic(size: 150),
                        draggable: true,
                        child: HomeBottom(auth.user!.email!,_storage),
                      ))
                  : _buildSuggestions(),
            ));
    //final wordPair = WordPair.random(); // NEW
    //return Text(wordPair.asPascalCase); // NEW
  }

  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        // The itemBuilder callback is called once per suggested
        // word pairing, and places each suggestion into a ListTile
        // row. For even rows, the function adds a ListTile row for
        // the word pairing. For odd rows, the function adds a
        // Divider widget to visually separate the entries. Note that
        // the divider may be difficult to see on smaller devices.
        itemBuilder: (BuildContext _context, int i) {
          // Add a one-pixel-high divider widget before each row
          // in the ListView.
          if (i.isOdd) {
            return Divider();
          }

          // The syntax "i ~/ 2" divides i by 2 and returns an
          // integer result.
          // For example: 1, 2, 3, 4, 5 becomes 0, 1, 1, 2, 2.
          // This calculates the actual number of word pairings
          // in the ListView,minus the divider widgets.
          final int index = i ~/ 2;
          // If you've reached the end of the available word
          // pairings...

          if (index >= _suggestions.length) {
            // ...then generate 10 more and add them to the
            // suggestions list.
            _suggestions.addAll(generateWordPairs().take(10));
          }
          return _buildRow(_suggestions[index]);
        });
  }

  Widget _buildRow(WordPair pair) {
    return Consumer<FavoritesRepository>(
      builder: (context, fave, _) => ListTile(
        title: Text(
          pair.asPascalCase,
          style: _biggerFont,
        ),
        trailing: Icon(
          // NEW from here...
          fave.currentSet.contains(pair)
              ? Icons.favorite
              : Icons.favorite_border,
          color: fave.currentSet.contains(pair) ? Colors.red : null,
        ),
        onTap: () {
          // NEW lines from here...
          if (fave.currentSet.contains(pair)) {
            fave.deleteSingleFavorite(pair);
          } else {
            fave.addSingleFavorite(pair);
          }
        },
      ),
    );
  }

  void _pushLogin() {
    TextEditingController emailController = new TextEditingController();
    TextEditingController passwordController = new TextEditingController();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
              appBar: AppBar(
                title: Text('Login'),
                centerTitle: true,
              ),
              body: Container(
                padding: EdgeInsets.fromLTRB(20, 30, 20, 20),
                child: Column(
                  children: [
                    Text(
                        'Welcome to Startup Names Generator, please log in below'),
                    Padding(padding: EdgeInsets.fromLTRB(20, 30, 20, 20)),
                    TextField(
                      decoration: InputDecoration(labelText: 'Email'),
                      controller: emailController,
                    ),
                    Padding(padding: EdgeInsets.fromLTRB(0, 20, 0, 0)),
                    TextField(
                      decoration: InputDecoration(labelText: 'Password'),
                      controller: passwordController,
                    ),
                    Padding(padding: EdgeInsets.fromLTRB(0, 20, 0, 0)),
                    ConstrainedBox(
                      constraints: BoxConstraints.tightFor(width: 400),
                      child: Consumer<AuthRepository>(
                        builder: (context, auth, _) => ElevatedButton(
                            onPressed: auth.status == Status.Authenticating
                                ? null
                                : () {
                                    _pushLoginButton(auth, emailController.text,
                                        passwordController.text);
                                  },
                            child: Text('Log in'),
                            style: ElevatedButton.styleFrom(
                              primary: Colors.red,
                            )),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints.tightFor(width: 400),
                      child: ElevatedButton(
                          onPressed: () {
                            _pushSignUpButton(
                                emailController.text, passwordController.text);
                          },
                          child: Text('New User? Click to sign up'),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.teal[700],
                          )),
                    ),
                  ],
                ),
              ));
        },
      ),
    );
  }

  void _pushSignUpButton(String email, String password) {
    TextEditingController confirmedController = new TextEditingController();

    showModalBottomSheet(
        context: context,
        builder: (context) {
          bool confirmedText = true;
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setStateModal) {
            return Wrap(
              children: [
                Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Column(children: [
                      Padding(padding: EdgeInsets.fromLTRB(0, 20, 0, 0)),
                      Text("Please confirm your password below:"),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Padding(padding: EdgeInsets.fromLTRB(20, 0, 0, 0)),
                          Container(
                            width: 350,
                            child: TextField(
                              controller: confirmedController,
                              obscureText: true,
                              decoration: InputDecoration(
                                  labelText: 'Password',
                                  errorText: confirmedText == false
                                      ? 'Passwords must match'
                                      : null,
                                  labelStyle: TextStyle(color: Colors.red)),
                            ),
                          ),
                          Padding(padding: EdgeInsets.fromLTRB(0, 0, 20, 0)),
                        ],
                      ),
                      Padding(padding: EdgeInsets.fromLTRB(0, 20, 0, 0)),
                      Consumer<AuthRepository>(builder: (context, auth, _) => ElevatedButton(
                            onPressed: () {
                              confirmAndSign(auth,
                                  email, password, confirmedController.text).then((value){
                                 if (!value){
                                   setStateModal(() {
                                     confirmedText=false;
                                   });
                                 }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                                primary: Colors.teal[700]),
                            child: Text("Confirm")),
                      ),
                      Padding(padding: EdgeInsets.fromLTRB(0, 20, 0, 0))
                    ])),
              ],
            );
          });
        });
  }

  Future<bool> confirmAndSign(AuthRepository auth, String email, String first, String second) async {
    if (first != second) {
      return false;
    }
    if (await auth.signUp(email, first)!=null){
      Navigator.pop(context);
      Navigator.pop(context);
    }


    return true;
  }

  void _pushLoginButton(AuthRepository auth, String email, String password) {
    auth.signIn(email, password).then((value) {
      if (value) {
        /*FavoritesRepository fav = new FavoritesRepository();
        fav.updateFavorites(auth);*/
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('There was an error logging into the app')));
      }
    });
  }

  void _deletePressed(WordPair pair, FavoritesRepository faves) {
    faves.deleteSingleFavorite(pair);
  }

  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        // NEW lines from here...

        builder: (BuildContext context) {
          final favorites =
              Provider.of<FavoritesRepository>(context).currentSet;
          if (favorites.isEmpty) {
            return Scaffold(
              appBar: AppBar(
                title: Text('Saved Suggestions'),
              ),
            );
          }
          final tiles = favorites.map(
            (WordPair pair) {
              return ListTile(
                title: Text(
                  pair.asPascalCase,
                  style: _biggerFont,
                ),
                trailing: Consumer<FavoritesRepository>(
                  builder: (context, fave, _) => IconButton(
                    icon: Icon(

                        // NEW from here...
                        Icons.delete_outline,
                        color: Colors.red),
                    onPressed: () {
                      _deletePressed(pair, fave);
                    },
                  ),
                ),
              );
            },
          );
          final divided = ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList();

          return Scaffold(
            appBar: AppBar(
              title: Text('Saved Suggestions'),
            ),
            body: ListView(children: divided),
          );
        }, // ...to here.
      ),
    );
  }
}
