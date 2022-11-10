import 'package:flutter/material.dart';
import 'package:hexabase/hexabase.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

const projectId = "636affb311092f02affd3adc";
const datastoreId = "636affd3a011d2ae2bbfe1af";
const email = "atsushi+demo@moongift.co.jp";
const password = ".@fuEozC8t6k.Ec__Ah";

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Hexabase();
    return MaterialApp(
      darkTheme: ThemeData.dark(),
      theme: ThemeData.light(),
      home: MainPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// メイン画面のステートフルウィジェット
class MainPage extends StatefulWidget {
  MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

// ログイン用ウィジェット
class _MainPageState extends State<MainPage> {
  bool isLogin = false;
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    final client = Hexabase.instance;
    final bol = await client.isLogin();
    setState(() {
      isLogin = bol;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 画面表示用のラベル
    return isLogin
        ? MemoListPage()
        : LoginPage(onLogin: () {
            // 認証完了したら受け取るコールバック
            setState(() {
              isLogin = true;
            });
          });
  }
}

// ログイン画面のステートフルウィジェット
class LoginPage extends StatefulWidget {
  final Function? onLogin;
  const LoginPage({Key? key, this.onLogin}) : super(key: key);

  @override
  LoginPageState createState() => LoginPageState();
}

// ログイン画面用ウィジェット
class LoginPageState extends State<LoginPage> {
  // サンプルの認証情報
  String _email = email;
  String _password = password;

  @override
  Widget build(BuildContext context) {
    // 画面表示用のラベル
    return Scaffold(
        // 画面上部に表示するAppBar
        appBar: AppBar(
          title: const Text("Login"),
        ),
        body: Container(
          // 余白を付ける
          padding: const EdgeInsets.all(64),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              // メールアドレス
              TextFormField(
                initialValue: _email,
                onChanged: (String value) {
                  _email = value;
                },
              ),
              const SizedBox(height: 8),
              // パスワード
              TextFormField(
                obscureText: true,
                initialValue: _password,
                onChanged: (String value) {
                  _password = value;
                },
              ),
              // ログイン実行用のボタン
              TextButton(onPressed: _login, child: const Text("Login"))
            ],
          ),
        ));
  }

  // ログイン処理
  void _login() async {
    // Hexabaseクライアントの呼び出し
    final client = Hexabase.instance;
    // 認証実行
    final bol = await client.login(_email, _password);
    // レスポンスが true なら認証完了
    if (bol) widget.onLogin!();
  }
}

// メモ一覧のステートフルウィジェット
class MemoListPage extends StatefulWidget {
  const MemoListPage({Key? key}) : super(key: key);

  @override
  MemoListPageState createState() => MemoListPageState();
}

// メモ一覧画面用ウィジェット
class MemoListPageState extends State<MemoListPage> {
  List<HexabaseItem> _memos = [];
  late HexabaseDatastore? _datastore;

  @override
  void initState() {
    super.initState();
    _getMemos();
  }

  // 登録されている写真メモを取得する
  void _getMemos() async {
    final client = Hexabase.instance;
    // データストアの設定
    _datastore = client.project(id: projectId).datastore(id: datastoreId);
    // 7日前のデータまでに限定
    var date = DateTime.now().subtract(const Duration(days: 7));
    var query = _datastore!.query();
    query.greaterThanOrEqualTo('created_at', date);
    // データの取得
    final items = await _datastore!.items(query: query);
    // ステートを更新
    setState(() {
      _memos = items;
    });
  }

  // 写真メモの追加画面への遷移用
  void _add() async {
    // 新しいTodoを取得
    final HexabaseItem? item = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) {
        // 新しいデータの作成
        var item = _datastore!.item();
        // タスクの追加、編集を行う画面への遷移
        return MemoPage(item: item);
      }),
    );
    // レスポンスがあれば、リストに追加
    // キャンセルされた場合は null が来る
    if (item != null) {
      setState(() {
        _memos.add(item);
      });
    }
  }

  // 詳細画面への遷移用
  void _show(HexabaseItem item) async {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      // タスクの追加、編集を行う画面への遷移
      return MemoDetailPage(item: item);
    }));
  }

  // 写真メモの削除処理
  void _delete(int index, DismissDirection direction) async {
    // スワイプされた要素をデータから削除する
    setState(() {
      // データストアから削除
      _memos[index].delete();
      // 配列からも削除
      _memos.removeAt(index);
    });
    // Snackbarを表示する
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Memo deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // 画面上部に表示するAppBar
        appBar: AppBar(
          title: const Text("Memos"),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _add,
            ),
          ],
        ),
        body: ListView.builder(
          itemCount: _memos.length,
          itemBuilder: (context, index) {
            final item = _memos[index];
            // スワイプで削除する機能
            return Dismissible(
                key: Key(item.id!),
                direction: DismissDirection.endToStart,
                // スワイプした際に表示する削除ラベル
                background: Container(
                    padding: const EdgeInsets.only(right: 20.0),
                    color: Colors.red.shade500,
                    child: const Align(
                      alignment: Alignment.centerRight,
                      child: Text('削除',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white)),
                    )),
                // スワイプした際に処理
                onDismissed: (direction) {
                  _delete(index, direction);
                },
                child: MemoRowPage(item: item, onTap: () => _show(item)));
          },
        ));
  }
}

// メモ一覧画面の、各行のステートフルウィジェット
class MemoRowPage extends StatefulWidget {
  const MemoRowPage({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  final HexabaseItem item;
  final Function onTap;

  @override
  MemoRowPageState createState() => MemoRowPageState();
}

// メモ一覧画面の各行用ウィジェット
class MemoRowPageState extends State<MemoRowPage> {
  Uint8List? _image; // 写真データが入る
  int _count = 0; // 写真の数が入る
  @override
  void initState() {
    super.initState();
    _getImage(); // 写真データ（1件）を取得
  }

  // 写真データ（1件）を取得
  Future<void> _getImage() async {
    // 詳細データを取得
    await widget.item.getDetail();
    // 写真データを取得（Nullの可能性がある）
    final photos = await widget.item.get('photo');
    // 写真データがなければ終了
    if (photos == null || photos.isEmpty) return;
    if (photos.first == null) return;
    // 写真の実データを取得
    final image = await photos.first.download() as Uint8List?;
    setState(() {
      _count = photos.length; // 全写真の数
      _image = image; // 写真の実データ
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: _count == 0 ? const Icon(Icons.note) : Image.memory(_image!),
        onTap: () => {widget.onTap()},
        title: Text(
          widget.item.getAsString('note', defaultValue: ""),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}

// メモの詳細表示用ステートフルウィジェット
class MemoDetailPage extends StatefulWidget {
  const MemoDetailPage({
    Key? key,
    required this.item,
  }) : super(key: key);

  final HexabaseItem item;

  @override
  MemoDetailPageState createState() => MemoDetailPageState();
}

// メモの詳細表示用ウィジェット
class MemoDetailPageState extends State<MemoDetailPage> {
  // 表示する写真（配列）
  List<Uint8List>? _images;

  @override
  void initState() {
    super.initState();
    _getImages(); // 写真の取得
  }

  // 写真を取得する（複数あり）
  Future<void> _getImages() async {
    // データの詳細を取得
    await widget.item.getDetail();
    // 写真の配列を取得（Nullの可能性あり）
    final photos = await widget.item.get('photo');
    // 写真がない場合は終了
    if (photos == null || photos.isEmpty) return;
    // 写真データの配列を用意
    final images = <Uint8List>[];
    for (final photo in photos) {
      // 写真データをダウンロード
      final image = await (photo as HexabaseFile).download() as Uint8List?;
      if (image != null) {
        images.add(image); // データがあれば追加
      }
    }
    // ステートを更新
    setState(() {
      _images = images;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 画面上部に表示するAppBar
      appBar: AppBar(
        title: const Text('Show memo'),
      ),
      body: Container(
        // 余白を付ける
        padding: const EdgeInsets.all(64),
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            // タスクの詳細
            Text(widget.item.getAsString('note', defaultValue: "")),
            const SizedBox(height: 8),
            Text(_images == null ? "No image" : "${_images!.length} images"),
            _images != null
                ? Expanded(
                    child: ListView.builder(
                      itemCount: _images!.length,
                      itemBuilder: (context, index) {
                        return Card(
                            margin: const EdgeInsets.all(8),
                            elevation: 0,
                            child: SizedBox(
                                height: 200,
                                child: Image.memory(_images![index])));
                      },
                    ),
                  )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}

// メモの追加用ステートフルウィジェット
class MemoPage extends StatefulWidget {
  const MemoPage({
    Key? key,
    required this.item,
  }) : super(key: key);

  final HexabaseItem item;

  @override
  MemoPageState createState() => MemoPageState();
}

// メモの追加用ウィジェット
class MemoPageState extends State<MemoPage> {
  // 画像選択用コントローラー
  final ImagePicker _picker = ImagePicker();
  // 選択した画像の数
  int _count = 0;

  // データストアへの保存・更新処理
  Future<void> _save() async {
    widget.item.isNotifyToSender = true;
    // データストアに保存
    await widget.item.save();
    // 前の画面に戻る
    Navigator.of(context).pop(widget.item);
  }

  // 画像選択時の処理
  Future<void> _pickImage() async {
    // 複数選択可能
    final images = await _picker.pickMultiImage();
    // リセット
    widget.item.set('photo', []);
    // 選択した画像数を反映
    setState(() {
      _count = images.length;
    });
    // 写真の選択していなければここで終わり
    if (images.isEmpty) return;
    for (var image in images) {
      // 画像データの読み込み
      final bytes = await image.readAsBytes();
      // HexabaseFileオブジェクトの作成
      final photo = HexabaseFile(
          name: image.name,
          contentType: image.mimeType ?? 'application/octet-stream');
      photo.data = bytes;
      // データストアにセット
      widget.item.add('photo', photo);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 画面表示用のラベル
    return Scaffold(
      // 画面上部に表示するAppBar
      appBar: AppBar(
        title: const Text('Add memo'),
      ),
      body: Container(
        // 余白を付ける
        padding: const EdgeInsets.all(64),
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            // タスクの詳細
            TextFormField(
              initialValue: widget.item.getAsString('note', defaultValue: ""),
              decoration: const InputDecoration(hintText: "Note"),
              maxLines: 5,
              onChanged: (String value) {
                widget.item.set('note', value); // 入力値をデータストアにセット
              },
            ),
            const Spacer(flex: 1),
            // 保存・更新ボタン
            TextButton(
              onPressed: _pickImage,
              child: const Text('Select images'),
            ),
            _count == 0
                ? const Text('No image selected')
                : Text('$_count images selected'),
            const Spacer(flex: 1),
            TextButton(onPressed: _save, child: const Text("Save note")),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}
