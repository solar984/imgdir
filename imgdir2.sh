#!/bin/bash
#
# Laszlo Hanyecz laszlo@heliacal.net
# 
# this script works on the current directory only
#

outfile=index.html
subdir=".t"
commentfile=".comments"
google_map_key="AIzaSyBoI8WKnp7haKVq4o0o5NDtTmMJ_YN7ylk"

staticbaseurl="http://crane.heliacal.net/~solar/static/"
bootstrap_css_url="${staticbaseurl}bootstrap-3.1.1-dist/css/bootstrap.min.css"
#bootstrap_theme_css_url="${staticbaseurl}bootstrap-3.1.1-dist/css/bootstrap-theme.min.css"
bootstrap_js_url="${staticbaseurl}bootstrap-3.1.1-dist/js/bootstrap.min.js"
html5shivjs_url="${staticbaseurl}html5shiv.js"
respondjs_url="${staticbaseurl}respond.min.js"
jquery_url="${staticbaseurl}jquery-1.11.1.min.js"

# CDN urls
#respondjs_url="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"
#html5shivjs_url="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"
#jquery_url="https://code.jquery.com/jquery-1.11.0.min.js"

mapw=530
maph=530

getcomment()
{
  comment=""
  if [ -f "${commentfile}" ]; then
    fn=$( echo -ne "${1}\t" )
    comment=$( grep "${fn}" "${commentfile}" | cut -f 2- )
    echo "fn = ${fn}  comnent = ${comment}"
  fi
}

getgps()
{
  echo "${exif}" | perl -e '
while(<>) 
{ 
  if( m/Latitude.*?([NS]).*?([0-9.]*?)d.*?([0-9.]*?)m.*?([0-9.]*?)s/ ) 
  { 
    #print "Direction=$1 Deg=$2 Min=$3 Sec=$4\n"; 
    $latdec=($2 + $3/60 + $4/3600) * ("$1" eq "N" ? 1 : -1); 
    #print "Latitude degrees: $latdec\n"; 
  }
  if( m/Longitude.*?([EW]).*?([0-9.]*?)d.*?([0-9.]*?)m.*?([0-9.]*?)s/ ) 
  { 
    #print "Direction=$1 Deg=$2 Min=$3 Sec=$4\n"; 
    $londec=($2 + $3/60 + $4/3600) * ("$1" eq "E" ? 1 : -1); 
    #print "Longitude degrees: $londec\n"; 
  }
};
if(defined($latdec) && defined($londec))
{
  print "$latdec,$londec\n";
}
'
}

html_top="
<!DOCTYPE html>
<html lang=\"en\">
<head>
  <meta charset=\"utf-8\">
  <meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
  <title></title>
  <link href=\"${bootstrap_css_url}\" rel=\"stylesheet\" />
  <!--<link href=\"${bootstrap_theme_css_url}\" rel=\"stylesheet\" />-->

  <!--[if lt IE 9]>
    <script src=\"${html5shivjs_url}\"></script>
    <script src=\"${respondjs_url}\"></script>
  <![endif]-->

  <style>
    body
    {
      background-color: #121212;
      color: #a0a0a0;
    }
    .info
    {
      font-size: 90%;
    }
    .panel-default, .panel
    {
      background-color: #202020;
    }
    pre
    {
      background-color: #202020;
      color: #d0d0d0;
    }
    .googlemap
    {
      width: ${mapw}px;
      height: ${maph}px;
    }
  </style>
</head>
<body>
  <div class=\"container\">
  <div class=\"row\">
"

html_bodyscripts="
  <script src=\"${jquery_url}\"></script>
  <script src=\"${bootstrap_js_url}\"></script>
"
html_bottom="
  </div>
  </div>
</body>
</html>
"

echo -n "${html_top}" > "${outfile}"
echo -n "\
  <p>Click the image for a larger version or click the file name below the thumbnail for the original version.</p>
" >> "${outfile}"

# Sometimes the pics off the camera are named in all caps so JPG instead of jpg
for i in *.JPG; do
  # no JPG files
  if [ "${i}" == "*.JPG" ]; then
    continue;
  fi

  # rename .JPG to .jpg
  mv "$i" "${i%%.JPG}.jpg"
done

# timestamp images with date from exif and auto rotate
jhead -ft -autorot *.jpg

# loop through images ordered chronologically
ix=0
#declare -a filelist
lsoutput=`ls --color=never -1Str *.{jpg,bmp} 2> /dev/null`
while read i; do
  filelist[ix]="${i}"
  echo "$ix -> ${filelist[$ix]}"
  (( ix++ ))
done <<< "${lsoutput}"
len=${#filelist[@]}

for (( j=0; j < $len; j++ )); do
  i="${filelist[$j]}";
  unset prev next
  #echo "i = ${i}"
  if [ "${j}" -ne "0" ]; then
    prev="${filelist[(( j-1 ))]}"
    #echo "prev = ${prev}"
  fi

  if [ "${j}" -lt $(( $len - 1 )) ]; then
    next="${filelist[(( j+1 ))]}"
    #echo "next = ${next}"
  fi

  if [ ! -d "${subdir}" ]; then
    mkdir -v "${subdir}"
    if [ ! -d "${subdir}" ]; then
      echo "Unable to create subdirectory, exiting"
      exit 1;
    fi
  fi

  base=${i%%.jpg}
  small="${subdir}/${base}.small.jpg"
  thumb="${subdir}/${base}.thumb.jpg"
  imgpage="${subdir}/${base}.html"
  anchor=${i}
  # see if there are comments
  getcomment "${i}"

  # create thumbs if needed
  if [ ! -f "${small}" ] ; then
    echo "Creating ${small}"
    convert -geometry 1024x768 "$i" "${small}"
  fi

  if [ ! -f "${thumb}" ] ; then
    echo "Creating ${thumb}"
    convert -geometry 270x202 "$i" "${thumb}"
  fi

  # get exif info (long multiline string)  
  exif=`jhead "$i"`
  
  # see if the image contained global position info
  latlon=`getgps`
  if [ "${latlon}" != "" ]; then
    # static map
    mapurl="https://maps.googleapis.com/maps/api/staticmap?center=${latlon}&markers=color:red%7Clabel=X%7C${latlon}&size=${mapw}x${maph}&scale=2&sensor=false&zoom=7"
    # iframe embedded map
    maphtml="
<iframe
  width=\"${mapw}\"
  height=\"${maph}\"
  frameborder=\"0\" 
  style=\"border:0\"
  src=\"https://www.google.com/maps/embed/v1/search?key=${google_map_key}&q=${latlon}&zoom=7\">
</iframe>"
  else
    mapurl=""
    maphtml=""
  fi

  # create page for image
  echo -ne "\
${html_top}
  <br />
  <div class=\"row\">
" > "${imgpage}"
  echo -ne "\
    <div class=\"col-xs-12\">
      <img class=\"center-block img-responsive img-thumbnail\" src=\"${base}.small.jpg\">
    </div>
  </div>
  <div class=\"row\">
    <div class=\"col-xs-6\">
" >> "${imgpage}"
  if [ "${prev}" != "" ]; then
    echo -e "      <a class=\"btn btn-info pull-left\" id=\"prevpic\" href=\"${prev%%.jpg}.html\">&lt;-</a>" >> "${imgpage}"
  fi
  echo -ne "\
    </div>
    <div class=\"col-xs-6\">
" >> "${imgpage}"
  if [ "${next}" != "" ]; then
    echo -e "      <a class=\"btn btn-info pull-right\" id=\"nextpic\" href=\"${next%%.jpg}.html\">-&gt;</a>" >> "${imgpage}"
  fi
  echo -ne "\
    </div>
  </div>
  <br />
  <div class=\"row\">
    <div class=\"col-md-6\">
      <div class=\"info\">${comment}</div>
      <a class=\"btn btn-primary btn-download\" role=\"button\" href=\"../${i}\">Click for full size image</a>
      <a class=\"btn btn-primary\" role=\"button\" href=\"../index.html#${anchor}\">Back to index</a>
    </div>
  </div>
  <br />
  <div class=\"row\">
    <div class=\"col-md-6\">
      <!--<a id=\"exifhideshow\" class=\"btn btn-primary\" role=\"button\">Show Exif data</a>-->
      <pre id=\"exifdata\">${exif}</pre>
    </div>
" >> "${imgpage}"
  if [ "${maphtml}" != "" ]; then
    echo -ne "\
    <div class=\"col-md-6\">
      <pre>${maphtml}</pre>
    </div>" >> "${imgpage}"
# static map, if the other one doesn't end up working out
#    echo -ne "\
#    <div class=\"col-md-6\">
#      <pre><a href=\"\"><img class=\"googlemap\" src=\"${mapurl}\" /></a></pre>
#    </div>" >> "${imgpage}"
  fi
  echo -ne "\
  </div>
${html_bodyscripts}
  <script>
    \$(function()
    {
      \$('#exifhideshow').click(function()
      {
        \$('#exifdata').show();
        \$('#exifhideshow').hide();
      });
      \$(document).keydown(function(e)
      {
        if(e.which == 37) // left arrow key
        {
          e.preventDefault();
          href=\$(\"#prevpic\").attr('href');
          if(href != null && href.length > 0)
          {
            window.location.href = href;
          }
          return false;
        }
        if(e.which == 39) // right arrow key
        {
          e.preventDefault();
          href=\$(\"#nextpic\").attr('href');
          if(href != null && href.length > 0)
          {
            window.location.href = href;
          }
          return false;
        }
      });
    });
  </script>
${html_bottom}" >> "${imgpage}"

  # url encode file names
  base=`echo -n "${base}" | perl -pe 's/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg'`

  # date/exposure info string
  infostring0=`jhead -c "$i" | cut -d \" -f 3-`
  infostring1=`stat "$i" -c %y | sed s/\.000000000//`

  echo -n "\
    <a id=\"${anchor}\"></a>
    <div class=\"item-wrapper col-xs-12 col-sm-6 col-md-4 col-lg-3\">
      <div class=\"panel\">
        <div class=\"panel-heading\">
          <div class=\"info\">${infostring0}</div>
          <div class=\"info\">${infostring1}</div>
        </div>
        <div class=\"panel-body\">
          <a href=\"${imgpage}\"><img class=\"img-thumbnail center-block\" src=\"${thumb}\"></a><br />
          <div class=\"info\">Download: <a href=\"${i}\">${i}</a></div>
          <div class=\"info\">${comment}</div>
        </div>
      </div>
    </div>
" >> "${outfile}"

  (( c++ ))
  if [ "$(( c % 4 ))" == "0" ]; then
    echo -e "    <div class=\"clearfix visible-lg\" ></div>" >> "${outfile}"
  fi
  if [ "$(( c % 3 ))" == "0" ]; then
    echo -e "    <div class=\"clearfix visible-md\" ></div>" >> "${outfile}"
  fi
  if [ "$(( c % 2 ))" == "0" ]; then
    echo -e "    <div class=\"clearfix visible-sm\" ></div>" >> "${outfile}"
  fi

done

echo -ne "${html_bodyscripts}\n${html_bottom}" >> "${outfile}"

