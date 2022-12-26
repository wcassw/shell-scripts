#!/bin/bash
# 
# 
CMD=/usr/bin/yd

cat >${CMD} <<EOF
#!/bin/bash
ARGS=1
E_BADARGS=1
TEM_FILE="/tmp/dict.tmp"
example_enable=false

if [ \$# -lt "\$ARGS" ]
 then
    echo "Usage:\$(basename \$0) word"
    exit \$E_BADARGS
fi

# getopts
while getopts "a" arg
do
  case \$arg in
    a)
      example_enable=true
      shift
      ;;
    ?)
    example_enable=false
    echo "unkown argument"
  exit 1
  ;;
  esac
done

keyword="\$*"
keyword=\${keyword// /%20}

# curl
curl -s 'http://dict.youdao.com/search?q='\$keyword'' | awk 'BEGIN{j=0;i=0;} {if(/phrsListTab/){i++;} if(i==1){print \$0; if(/<\/ul>/){i=0;}} if(/collinsToggle/){ j++;} if(j==1) {print \$0; if(/<\/ul>/){j=0;}}}' | sed 's/<[^>]*>//g' | sed 's/&nbsp;//g'| sed 's/&rarr;//g' | sed 's/^\s*//g' | sed '/^$/d'> \$TEM_FILE

# 
is_head=true 
head="" 
body="" 
ln_item=0 
ln_eg=0 

while read line
do
    let ln_item++
    let ln_eg++
    num_flag=\$(echo "\$line" | awk '/[0-9]+\.\$/')
    if [ "\$num_flag" != "" ]; then 
        is_head=false 
        ln_item=0
    fi

    eg_flag=\$(echo "\$line" | awk '/例：\$/') 
    if [ "\$eg_flag" != "" ]; then
        ln_eg=0
    fi

    if \$is_head ; then
        head="\$head \$line"
    else
        if [ \$ln_item == 0 ] ; then
            line="\033[32;1m\n\n\$line\033[0m" 
        elif [ \$ln_item == 1 ] ; then
            line="\033[32;1m[\$line]\033[0m" 
        elif [ \$ln_item == 2 ] ; then
            line="\033[1m\$line\033[0m" 
        elif [ \$ln_eg == 0 ] ; then
            line="\033[32;1m\n   \$line\033[0m"
        elif [ \$ln_eg == 1 ]; then
            line="\033[33m\$line\033[0m" 
        elif [ \$ln_eg == 2 ]; then
            line="\033[33m\$line\033[0m" 
        fi
        body="\$body \$line"
    fi
done < \$TEM_FILE
if \$example_enable
then
    echo -e "\033[31;1m\$head\033[0m \$body"
else
    echo -e "\033[31;1m\$head"
fi
echo -e "\033[33m <http://dict.youdao.com>\033[0m"
exit 0
EOF

chmod +x ${CMD}

