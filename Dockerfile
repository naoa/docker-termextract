FROM centos:6.4
MAINTAINER Naoya Murakami <naoya@createfield.com>

ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja
ENV LC_ALL ja_JP.UTF-8
#RUN echo 'LANG="ja_JP.utf8"' >> /etc/sysconfig/i18n

RUN yum install -y wget tar vi nkf
RUN yum install -y gcc make gcc-c++
RUN yum install -y perl perl-devel

# for debian
#RUN apt-get update
#RUN apt-get install -y wget tar vim nkf
#RUN apt-get install -y gcc make g++
#RUN apt-get install -y perl libperl-dev

# Mecab
RUN wget https://mecab.googlecode.com/files/mecab-0.996.tar.gz
RUN tar -xzf mecab-0.996.tar.gz
RUN cd mecab-0.996; ./configure --enable-utf8-only; make; make install; ldconfig

# Ipadic
RUN wget https://mecab.googlecode.com/files/mecab-ipadic-2.7.0-20070801.tar.gz
RUN tar -xzf mecab-ipadic-2.7.0-20070801.tar.gz
RUN cd mecab-ipadic-2.7.0-20070801; ./configure --with-charset=utf8; make; make install
RUN echo "dicdir = /usr/local/lib/mecab/dic/ipadic" > /usr/local/etc/mecabrc

# Mecab-perl
RUN wget https://mecab.googlecode.com/files/mecab-perl-0.996.tar.gz
RUN tar -xzf mecab-perl-0.996.tar.gz
RUN cd mecab-perl-0.996 ;perl Makefile.PL; make ;make install;
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/mecab.conf
RUN ldconfig

# TermExtract
RUN wget http://gensen.dl.itc.u-tokyo.ac.jp/soft/TermExtract-4_10.tar.gz
RUN tar -xzf TermExtract-4_10.tar.gz
RUN cd TermExtract-4_10 ;perl Makefile.PL; make ;make install;

# Add perl script
ADD termextract_mecab.pl /usr/local/bin/termextract_mecab.pl
RUN chmod 755 /usr/local/bin/termextract_mecab.pl

# Clean up
RUN rm -rf mecab-0.996.tar.gz*
RUN rm -rf mecab-perl-0.996.tar.gz* 
RUN rm -rf mecab-ipadic-2.7.0-20070801*
RUN rm -rf TermExtract-4_10.tar.gz*

