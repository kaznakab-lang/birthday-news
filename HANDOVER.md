# 誕生日報（お誕生日新聞） — 引継ぎメモ

会話をまたいで続きをするときは、まずこれを読む。

## アプリの考え方
- 名前と生年月日を入れると、生まれた日のニュースと写真でA3片面の記念新聞ができる。大人の誕生日の贈り物。
- 紙面の確認は無料。A3印刷用PDFの保存だけ有料（App内課金・消耗型、1枚ごと。仮の値段200円）。
- サーバーなし。記事は作り置きのデータ（data/）。写真は表示のたびに Wikimedia Commons から取得（APIキー不要）。
- iPhoneアプリだけで出す。Web版（GitHub Pages）はリリース時に止める。

## 決めたこと
- アプリ名：「誕生日報」（App Storeの名前は「誕生日報 - 生まれた日の記念新聞」。リポジトリ名などの内部の名前は birthday-news のまま）
- bundle id：`com.kutalabo.birthdaynews`（`project.yml` と `codemagic.yaml` の両方。片方だけ直さない）
- App内課金の商品ID：`com.kutalabo.birthdaynews.pdf`（消耗型）。`BirthdayNews/Models/PurchaseManager.swift` と同じにする
- 置き場所：`C:\dev\BIRTHDAY-NEWS`。ビルドは Codemagic（宝くじチェックと同じ作り：XcodeGen → xcodebuild）
- 対象：1930〜2025年生まれ
- 背景は白。コンビニ印刷はAPIを使わない：
  - ローソン・ファミマ：シャープの会員登録なしの登録ページ（https://networkprint.ne.jp/Lite/start）をアプリ内で開く
  - セブン-イレブン：共有シートで「かんたんnetprint」へPDFを渡す
  - 印刷代の金額は書かない（「別途、コンビニでのお支払い」とだけ書く）

## 仕組み
- 紙面は `paper.html`＋`js/paper.js`＋`css/paper.css` をアプリにそのまま入れ、WKWebView に `bnews://app/paper.html?…` で表示する（`BirthdayNews/Web/PaperWeb.swift`）
- `paper.html` のパラメータ：`app=1` アプリ表示／`wm=1` 見本の透かし／`pdf=1` PDF用の等倍表示。準備ができると `webkit.messageHandlers.paper` に `{state:"ready"}` を送る
- PDF：画面の裏に等倍の紙面を読み込み → `createPDF` → A3（841.89×1190.55pt）に描き直す（`BirthdayNews/Web/PDFMaker.swift`）

## ファイルの場所
- `BirthdayNews/Views/` … つくる・プレビュー・保存共有・作った新聞・印刷のしかた
- `BirthdayNews/Models/PaperRecord.swift` … 入力内容と購入済みかどうか（端末に保存）
- `BirthdayNews/Models/PurchaseManager.swift` … App内課金（StoreKit 2）
- `data/years|months|days/` … 記事データ。作り方は `AGENT_YEARS.md`・`AGENT_MONTHS.md`・`AGENT_DAYS.md`・`AGENT_STARS.md`

## モックアップ
claude.ai の「お誕生日新聞 アプリ画面」（Design）に、つくる・プレビュー・購入後・作った新聞・印刷のしかた・ローソン/ファミマの画面がある。
