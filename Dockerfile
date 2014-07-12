#FROM centos:centos6
FROM centos:centos7
MAINTAINER Naoya Murakami <naoya@createfield.com>

RUN localedef -f UTF-8 -i ja_JP ja_JP.utf8
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja
ENV LC_ALL ja_JP.UTF-8

RUN yum install -y wget tar vi bzip2
RUN yum install -y gcc make gcc-c++
RUN yum install -y perl perl-devel
#RUN yum install -y nkf
RUN yum localinstall -y http://mirror.centos.org/centos/6/os/x86_64/Packages/nkf-2.0.8b-6.2.el6.x86_64.rpm

# for debian
#RUN apt-get update
#RUN apt-get install locales
#RUN apt-get install -y wget tar vim nkf bzip2
#RUN apt-get install -y gcc make g++
#RUN apt-get install -y perl libperl-dev

# Mecab
RUN wget http://mecab.googlecode.com/files/mecab-0.996.tar.gz
RUN tar -xzf mecab-0.996.tar.gz
RUN cd mecab-0.996; ./configure --enable-utf8-only; make; make install; ldconfig

# Ipadic
RUN wget http://mecab.googlecode.com/files/mecab-ipadic-2.7.0-20070801.tar.gz
RUN tar -xzf mecab-ipadic-2.7.0-20070801.tar.gz
RUN cd mecab-ipadic-2.7.0-20070801; ./configure --with-charset=utf8; make; make install
RUN echo "dicdir = /usr/local/lib/mecab/dic/ipadic" > /usr/local/etc/mecabrc

# Ipadic_model
RUN wget http://mecab.googlecode.com/files/mecab-ipadic-2.7.0-20070801.model.bz2
RUN bzip2 -d mecab-ipadic-2.7.0-20070801.model.bz2
#RUN iconv -f EUCJP -t UTF-8 mecab-ipadic-2.7.0-20070801.model -o mecab-ipadic-2.7.0-20070801.model
RUN nkf --overwrite -Ew mecab-ipadic-2.7.0-20070801.model
RUN sed -i -e "s/euc-jp/utf-8/g" mecab-ipadic-2.7.0-20070801.model

# Mecab-perl
RUN wget http://mecab.googlecode.com/files/mecab-perl-0.996.tar.gz
RUN tar -xzf mecab-perl-0.996.tar.gz
RUN cd mecab-perl-0.996 ;perl Makefile.PL; make ;make install;
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/mecab.conf
RUN ldconfig

# TermExtract
RUN wget http://gensen.dl.itc.u-tokyo.ac.jp/soft/TermExtract-4_10.tar.gz
RUN tar -xzf TermExtract-4_10.tar.gz
RUN nkf --overwrite -Ew /TermExtract-4_10/TermExtract/MeCab.pm
RUN cd TermExtract-4_10 ;perl Makefile.PL; make ;make install;

# Add perl script
ADD termextract_mecab.pl /usr/local/bin/termextract_mecab.pl
RUN chmod 755 /usr/local/bin/termextract_mecab.pl

VOLUME ["/var/lib/termextract"]

ADD pre_filter.txt /var/lib/termextract/pre_filter.txt
ADD post_filter.txt /var/lib/termextract/post_filter.txt

# Clean up
RUN rm -rf mecab-0.996.tar.gz*
RUN rm -rf mecab-ipadic-2.7.0-20070801.tar.gz*
RUN rm -rf mecab-perl-0.996.tar.gz* 
RUN rm -rf TermExtract-4_10.tar.gz*

