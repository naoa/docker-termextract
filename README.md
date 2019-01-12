# docker-termextract

専門用語（キーワード）自動抽出用Perlモジュール"TermExtract"を簡単に使うためのDockerイメージを作成するDockerfileです。 

* 専門用語（キーワード）自動抽出用Perlモジュール"TermExtract"  
http://gensen.dl.itc.u-tokyo.ac.jp/termextract.html

* "TermExtract"のCOPYRIGHT  
東京大学・中川裕志教授、横浜国立大学・森辰則助教授が 作成した「専門用語自動抽出システム」のExtract.pm を参考に、中川教授の 教示を受け、東京大学経済学部・前田朗が全面的に組みなおしたもの。(敬省略)   

このDockerfileでは、以下の環境のコンテナが構築されます。

| 項目        | バージョン | 備考 |
|:-----------|:------------|:------------|
| CentOS     | 7 | ja_JP.UTF-8|
| perl | 5.16.3 | yum base |
| MeCab     | 0.996 | --enable-utf8-only|
| MeCab IPAdic | 2.7.0-20070801 |--with-charset=utf8|
| MeCab IPAdic model | 2.7.0-20070801 ||
| MeCab perl | 0.996 ||
| TermExtract | 4_10 ||

## イメージ構築

```bash
% git clone git@github.com:naoa/docker-termextract.git
% cd docker-termextract
% docker-compose build
% docker-compose up -d
```

## 使い方
* コンテナにターミナル接続する場合  
```bash
% docker-compose exec termextract bash
bash-4.1#termextract_mecab.pl
印刷用紙を複合機で印刷する。
EOS
複合機                                                                8.21
印刷用紙                                                             3.00
```

入力を終了するにはEOSを入力します。  

* 形態素解析済みテキストファイルから専門用語を抽出する場合  

```bash
% cat { 形態素解析済みテキストファイル}.txt || termextract_mecab.pl --is_mecab
```

* 入力形式  
UTF8の文字コードのテキストのみ対応しています。

| 引数        | 説明       |デフォルト   |
|:-----------|:------------|:------------|
| --input または 引数なし | 標準入力または解析対象ファイル名(コンテナ内の)|標準入力|
| --output | 1:専門用語+重要度、2:専門用語のみ、3:カンマ区切り、4:IPAdic辞書形式(コスト推定)、5:IPAdic辞書形式(文字列長)|1|
| --limit | 出力件数|-1(すべて)|
| --threshold | 閾値|-1(すべて)|
| --is_mecab | 入力を形態素解析済みの形式とする||
| --no_dic_filter | MeCabの辞書に登録済みの専門用語を出力する||
| --no_term_extract | 形態素解析、専門用語抽出を行わずコスト推定のみ行う||
| --stat_db |過去のドキュメントの累積統計を使う場合のデータベースのファイル名(<code>/var/lib/termextract/</code>配下)|"stat_db"|
| --comb_db |過去のドキュメントの累積統計を使う場合のデータベースのファイル名(<code>/var/lib/termextract/</code>配下)|"comb_db"|
| --no_stat |重要度計算で学習機能を使わない||
| --no_storage |学習機能用DBにデータを蓄積しない||
| --average_rate |重要度計算で、「ドキュメント中の用語の頻度」と「連接語の重要度」のどちらに比重をおくか。値が大きいほど「ドキュメント中の用語の頻度」の比重が高まる|1|
| --pre_filter |形態素解析の前にプレーンテキストから除去する正規表現パターンがリストされたファイル名(<code>/var/lib/termextract/</code>配下)|"pre_filter.txt"|
| --post_filter |複合語抽出の後に出力しない正規表現パターンがリストされたファイル名(<code>/var/lib/termextract/</code>配下)|"post_filter.txt"|
| --use_total |重要度計算で連接語の延べ数をとる|ON|
| --use_uniq |重要度計算で連接語の異なり数をとる||
| --use_Perplexity |重要度計算で連接語のパープレキシティをとる||
| --no_LR |重要度計算で連接語の隣接情報を使わない||
| --use_TF |重要度計算で連接情報に掛け合わせる用語出現頻度情報 TF||
| --use_frq |重要度計算で、連接情報に掛け合わせる用語出現頻度情報 Frequencyによる用語頻度|ON|
| --no_frq |重要度計算で、連接情報に掛け合わせる用語出現頻度情報 頻度情報を使わない||
| --use_SDBM |学習機能用DBに使用するDBMをSDBM_Fileに指定する||
| --lock_dir |データベースの排他ロックのための一時ディレクトリを指定|ロックしない|

* 出力結果  
<code>--output</code>に指定したモードに沿った解析結果のテキストがUTF8の文字コードで標準出力に出力されます。

4を指定するとMeCabで自動コスト推定したIPAdic形式の文字列が出力されます。  

```bash
% echo "印刷用紙を複合機で印刷する。" | \
  docker run -v /var/lib/termextract:/var/lib/termextract \
  -a stdin -a stdout -a stderr -i naoa/termextract termextract_mecab.pl --output 4
複合機,1285,1285,7336,名詞,一般,*,*,*,*,複合機,*,*,ByTermExtractEst
印刷用紙,1285,1285,7336,名詞,一般,*,*,*,*,印刷用紙,*,*,ByTermExtractEst
```

5を指定すると文字列長に応じてコストが手動で設定されたIPAdic形式の文字列が出力されます。  

```bash
% echo "印刷用紙を複合機で印刷する。" | \
  docker run -v /var/lib/termextract:/var/lib/termextract \
  -a stdin -a stdout -a stderr -i naoa/termextract termextract_mecab.pl --output 5 
複合機,0,0,-14500,名詞,一般,*,*,*,*,複合機,*,*,ByTermExtractLen
印刷用紙,0,0,-16000,名詞,一般,*,*,*,*,印刷用紙,*,*,ByTermExtractLen
```

<code>--no_term_extract</code>を指定すると形態素解析、専門用語抽出をせずにMeCabで自動コスト推定したIPAdic形式の文字列が出力されます。  

```bash
% echo "印刷用紙" | docker run -v /var/lib/termextract:/var/lib/termextract \
  -a stdin -a stdout -a stderr -i naoa/termextract termextract_mecab.pl --no_term_extract
印刷用紙,1285,1285,7336,名詞,一般,*,*,*,*,印刷用紙,*,*,ByMeCabEst
```

* 参考：MeCabのIPAdicでの解析結果
```bash
% echo "印刷用紙を複合機で印刷する。" | \
  docker run -v /var/lib/termextract:/var/lib/termextract \
  -a stdin -a stdout -a stderr -i naoa/termextract mecab
印刷    名詞,サ変接続,*,*,*,*,印刷,インサツ,インサツ
用紙    名詞,一般,*,*,*,*,用紙,ヨウシ,ヨーシ
を      助詞,格助詞,一般,*,*,*,を,ヲ,ヲ
複合    名詞,サ変接続,*,*,*,*,複合,フクゴウ,フクゴー
機      名詞,接尾,一般,*,*,*,機,キ,キ
で      助詞,格助詞,一般,*,*,*,で,デ,デ
印刷    名詞,サ変接続,*,*,*,*,印刷,インサツ,インサツ
する    動詞,自立,*,*,サ変・スル,基本形,する,スル,スル
。      記号,句点,*,*,*,*,。,。,。
EOS
```

* システム辞書への追加例

```bash
% docker run -v /var/lib/termextract:/var/lib/termextract -i -t naoa/termextract /bin/bash
% echo "印刷用紙を複合機で印刷する。" | termextract_mecab.pl --output 4 > /mecab-ipadic-2.7.0-20070801/user.csv
% cd /mecab-ipadic-2.7.0-20070801
% nkf -e --overwrite user.csv
% make clean
% ./configure --with-charset=utf8; make; make install
% echo "印刷用紙を複合機で印刷する。" | mecab
印刷用紙        名詞,一般,*,*,*,*,印刷用紙,*,*,ByTermExtractEst
を      助詞,格助詞,一般,*,*,*,を,ヲ,ヲ
複合    名詞,サ変接続,*,*,*,*,複合,フクゴウ,フクゴー
機      名詞,接尾,一般,*,*,*,機,キ,キ
で      助詞,格助詞,一般,*,*,*,で,デ,デ
印刷    名詞,サ変接続,*,*,*,*,印刷,インサツ,インサツ
する    動詞,自立,*,*,サ変・スル,基本形,する,スル,スル
。      記号,句点,*,*,*,*,。,。,。
EOS
```

## Author

Naoya Murakami naoya@createfield.com

## License

Public domain. You can copy and modify this project freely.

