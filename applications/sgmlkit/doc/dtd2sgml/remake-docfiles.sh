#! /bin/sh -

BUILD_DIR=/home/norman/s/src/sgml/w/sgml/doc/dtd2sgml
TARGET_DIR=/home/norman/public_html/star/sgml/project

STARLINK_SGML_DIR=/home/norman/s/src/sgml/w/sgml
export STARLINK_SGML_DIR

cd $BUILD_DIR

# Don't produce any output unless the make fails
make general-0.7.html >make.log 2>&1 || cat make.log
if test ! -e $TARGET_DIR/general-0.7.html -o \
	general-0.7.html -nt $TARGET_DIR/general-0.7.html; then 
    cp general-0.7.html $TARGET_DIR
fi

make programcode-0.7.html > make.log 2>&1 || cat make.log
if test ! -e $TARGET_DIR/programcode-0.7.html -o \
	programcode-0.7.html -nt $TARGET_DIR/programcode-0.7.html; then 
    cp programcode-0.7.html $TARGET_DIR
fi

exit
