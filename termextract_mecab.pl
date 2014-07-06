#!/usr/bin/perl -w

#  termextract_mecab.pl
#
#　ファイルから「和布蕪」の形態素解析済みのデータ
#  またはプレーンテキストを読み取り
#  標準出力に専門用語とその重要度を返すプログラム
#
#   version 0.32
#
#   maeda@lib.u-tokyo.ac.jp
#
#   modified: Naoya Murakami <naoya@createfield.com>
#   コマンドラインからオプションを設定できるように修正
#   入力文字コードがUTF8で受け付けられるように修正
#   出力文字コードをUTF8に修正
#   MeCab未解析モードを追加
#   Mecabが知っている単語は出力させないモードを追加
#   カンマが含まれているものは出力させないように修正
#   $output_mode 4:IPADic形式を追加

use MeCab;
use TermExtract::MeCab;
use Getopt::Long;
use Encode;

#use strict;

$mecab = new MeCab::Tagger ();
my $db_dir = "/var/lib/termextract/";

my $data = new TermExtract::MeCab;

my %opts = ( input => "", output => 1,
             no_mecab => 0, no_dic_filter => 0,
             no_stat => 0, no_storage => 0,
             stat_db => "stat.db",
             comb_db => "comb.db",
             average_rate => 1,
             use_total => 0, use_uniq => 0,
             use_Perplexity => 0, no_LR => 0,
             use_TF => 0, use_frq => 0, no_frq => 0,
             use_SDBM => 0,
             lock_dir => "");

GetOptions(\%opts, qw( input=s output=i no_mecab no_dic_filter
                       stat_db=s comb_db=s average_rate=f
                       no_stat no_storage use_total use_uniq use_Perplexity
                       no_LR use_TF use_frq no_frq use_SDBM lock_dir=s) ) or exit 1;

$opts{stat_db} = $db_dir . $opts{stat_db};
$opts{comb_db} = $db_dir . $opts{comb_db};

my $InputFile = "";
my $str = "";
if (defined $ARGV[0]){
  $InputFile = $ARGV[0];
} elsif ($opts{input} eq ''){
  while (defined(my $line = <STDIN>)){
    if ($line eq "EOS\n") {
      last;
    }
    $str .= $line;
  }
} else {
  $InputFile = $opts{input};
}
if ( $InputFile ne '' ) {
  open (IN, $InputFile) or die "$!";
  while (<IN>) {
    $str .= $_;
  }
  close (IN);
}

if($opts{no_mecab} == 0){
  $str = $mecab->parse($str);
}

Encode::from_to($str,'utf8','euc-jp');

# プロセスの異常終了時処理
# (ロックディレクトリを使用した場合のみ）
$SIG{INT} = $SIG{QUIT} = $SIG{TERM} = 'sigexit';

# 出力モードを指定
# 1 → 専門用語＋重要度、2 → 専門用語のみ
# 3 → カンマ区切り
# 4 → IPADic形式
my $output_mode = $opts{output};

#
# 重要度計算で、連接語の"延べ数"、"異なり数"、"パープレキシティ"のい
# ずれをとるか選択。パープレキシティは「学習機能」を使えない
# また、"連接語の情報を使わない"選択もあり、この場合は用語出現回数
# (と設定されていればIDFの組み合わせ）で重要度計算を行う
# （デフォルトは"延べ数"をとる $obj->use_total)
#

if($opts{use_total}) {
  $data->use_total;      # 延べ数をとる
}
if($opts{use_uniq}) {
  $data->use_uniq;       # 異なり数をとる
}
if($opts{use_Perplexity}) {
  $data->use_Perplexity; # パープレキシティをとる(TermExtract 3.04 以上)
}
if($opts{no_LR}) {
  $data->no_LR;          # 隣接情報を使わない (TermExtract 4.02 以上)
}

#
# 重要度計算で、連接情報に掛け合わせる用語出現頻度情報を選択する
# $data->no_LR; との組み合わせで用語出現頻度のみの重要度も算出可能
# （デフォルトは "Frequency" $data->use_frq)
# TFはある用語が他の用語の一部に使われていた場合にもカウント
# Frequency は用語が他の用語の一部に使われていた場合にカウントしない
#
if($opts{use_TF}) {
  $data->use_TF;   # TF (Term Frequency) (TermExtract 4.02 以上)
}
if(!$opts{use_TF}) {
  $data->use_frq;  # Frequencyによる用語頻度
}
if($opts{no_frq}) {
  $data->no_frq;   # 頻度情報を使わない
}

#
# 重要度計算で、学習機能を使うかどうか選択
# （デフォルトは、使用しない $obj->no_stat)
#
if($opts{no_stat}) {
  $data->no_stat;  # 学習機能を使わない
} else {
  $data->use_stat; # 学習機能を使う
}

#
# 重要度計算で、「ドキュメント中の用語の頻度」と「連接語の重要度」
# のどちらに比重をおくかを設定する。
# デフォルト値は１
# 値が大きいほど「ドキュメント中の用語の頻度」の比重が高まる
#
$data->average_rate($opts{average_rate});

#
# 学習機能用DBにデータを蓄積するかどうか選択
# 重要度計算で、学習機能を使うときは、セットしておいたほうが
# 無難。処理対象に学習機能用DBに登録されていない語が含まれる
# と正しく動作しない。
# （デフォルトは、蓄積しない $obj->no_storage）
#
if($opts{no_storage}) {
  $data->no_storage;  # 蓄積しない
} else {
  $data->use_storage; # 蓄積する
}

#
# 学習機能用DBに使用するDBMをSDBM_Fileに指定
# （デフォルトは、DB_FileのBTREEモード）
#
if($opts{use_SDBM}) {
  $data->use_SDBM;
}

# 過去のドキュメントの累積統計を使う場合のデータベースの
# ファイル名をセット
# （デフォルトは "stat.db"と"comb.db"）
#

$data->stat_db($opts{stat_db});
$data->comb_db($opts{comb_db});

#
# データベースの排他ロックのための一時ディレクトリを指定
# ディレクトリ名が空文字列（デフォルト）の場合はロックしない
#
#$data->lock_dir("lock_dir");

#
# 「形態素解析」済みのテキストファイルから、データを読み込み
#  専門用語リストを配列に返す
#  （累積統計DB使用、ドキュメント中の頻度使用にセット）
#
my @noun_list = $data->get_imp_word($str, 'var'); # 入力が変数

# 前回読み込んだ「形態素解析」済みテキストファイルを元に
# モードを変えて、専門用語リストを配列に返す
#$data->use_stat->no_frq;
#my @noun_list2 = $data->get_imp_word();
# また、その結果を別のモードによる結果と掛け合わせる
#@noun_list = $data->result_filter (\@noun_list, \@noun_list2, 30, 1000);

#
#  専門用語リストと計算した重要度を標準出力に出す
#
foreach (@noun_list) {
   # utf8で出力
   Encode::from_to($_->[0], 'euc-jp', 'utf8');
   Encode::from_to($_->[1], 'euc-jp', 'utf8');

   # 日付・時刻は表示しない
   next if $_->[0] =~ /^(昭和)*(平成)*(\d+年)*(\d+月)*(\d+日)*(午前)*(午後)*(\d+時)*(\d+ 分)*(\d+秒)*$/;
   # 数値のみは表示しない
   next if $_->[0] =~ /^\d+$/;
   # カンマが含まれているものは表示しない
   next if $_->[0] =~ /,/;

   # MeCab辞書に含まれているものは表示しない (未知語でないものが1個だけだった場合)
   if ($opts{no_dic_filter} == 0) {
      $mecab_miti = new MeCab::Tagger ('-F%f[0]\n -U\0 -E\0');
      $miti_parsed = $mecab_miti->parse($_->[0]);
      my $count = (() = $miti_parsed =~ /[\n]/g);
      if($count == 1){
        #printf "辞書登録あり:%s\n", $_->[0];
        next;
      } else {
        #printf "辞書登録なし%d:%s\n", $count, $_->[0];
      }
   }

   # 結果表示
   printf "%-60s %16.2f\n", $_->[0], $_->[1] if $output_mode == 1;
   printf "%s\n",           $_->[0]          if $output_mode == 2;
   printf "%s,",            $_->[0]          if $output_mode == 3;
   printf "%s,0,0,%d,名詞,一般,*,*,*,*,%s,*,*,By TermExtract\n",
           $_->[0],-10000-length($_->[0])*500,$_->[0]  if $output_mode == 4;
}

# プロセスの異常終了時にDBのロックを解除
# (ロックディレクトリを使用した場合のみ）
sub sigexit {
   $data->unlock_db;
}
