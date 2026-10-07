# 月日データ（data/days/MM-DD.json）の作り方 — 作業者向け

お誕生日新聞（大人の誕生日に贈るA3の記念新聞）の「○月○日特集」欄のデータを作る。
手本：`data/days/10-06.json`（必ず最初に読むこと）。形式はこれと完全に同じにする。

## 形式

```json
{
  "features": [ { "year": 1889, "title": "…", "body": ["…"], "photo": { "q": "英語の検索語" } }, … 3件 ],
  "more":     [ { "year": 1908, "text": "…" }, … 5〜6件、年の古い順 ],
  "people":   [ { "name": "…", "born": 1887, "bio": "…", "photo": { "q": "英語の検索語" } }, … 3〜4人 ],
  "calendar": { "kinenbi": "…の日" }
}
```

## 文字数（厳守。欄の高さが決まっている）

- features.title：12字以内
- features.body：1段落、130〜150字（句読点込み）
- more.text：30〜60字。体言止め・短文でよい
- people.name：14字以内。bio：70〜90字
- calendar.kinenbi：日本の記念日を1〜2個、「・」でつなぎ全体25字以内

## 内容の選び方

- 必ずその月日（その日付ちょうど）に起きた出来事・生まれた人だけ。年は問わない
- 贈り物なので、明るい・文化的・発明・スポーツ・世界初・開業・開通などを優先。
  テロ・大量死・事故・処刑・暗殺はfeaturesには入れない（moreに歴史的大事件として1件までは可）
- features 3本のうち少なくとも1本は日本の出来事。more にも日本の出来事を2件以上
- 世界史・日本史の教科書級で、写真が Wikimedia Commons にありそうな題材を選ぶ
- people：故人のみ（存命の人は入れない）。日本人を1人以上。誰でも名前を知っている人を優先。
  紹介は「生まれ・職業・代表作や功績」。犯罪者・独裁者・戦争責任者は入れない
- 同じ題材を features と more で重複させない

## 文体

新聞記事の常体（である調）。手本と同じ調子。数字は算用数字。かぎかっこは「」。
「{」「}」の文字は使わない。誇張や推測は書かない。

## 事実確認（最重要）

- すべての日付・年・数字・人名を WebFetch で日本語版または英語版 Wikipedia
  （例 https://ja.wikipedia.org/wiki/10月7日 、各記事の個別ページ）で確認する
- 日付ページの一覧だけでなく、features と people は個別記事でも日付を確かめる
- 確認できない内容は使わず、別の題材に替える

## 写真の検索語（photo.q）

Wikimedia Commons を英語で検索して最初に見つかる自由ライセンス写真が使われる。
題材そのものが写る短い英語（例 "Moulin Rouge Paris", "Shinkansen 0 series 1964", "Thor Heyerdahl"）。
人物は名前だけ（例 "Le Corbusier"）。

## 出力

`/tmp/claude-0/-home-claude/63e8176e-bb3a-5774-821f-d9ceb0236b0c/scratchpad/site/data/days/MM-DD.json`
（UTF-8、インデント2、ensure_ascii=False 相当）。書いたら python3 で json として読めるか確かめる。
最後に、担当した日付ごとに「確認に使ったURL」と「自信のない点」を短く報告する。
