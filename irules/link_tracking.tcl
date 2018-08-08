ltm rule /Common/link_tracking {
when HTTP_REQUEST {

  set TABLE_LINK    "LINK_TRACKING_[virtual name]";
  set TABLE_FILTERS "LINK_TRACKING_FILTERS_[virtual name]";

  switch -glob [string tolower [HTTP::uri]] {
    "/linkadmin*" {
      set count_filter "";
      set data_filter "";
      set msg [URI::decode [getfield [HTTP::uri] "/" 3]]
      if { ($msg starts_with "f(") && ($msg ends_with ")") } {
        set count_filter "";
        set data_filter [string range $msg 2 end-1];
        set msg "";
      } elseif { ($msg starts_with "c(") && ($msg ends_with ")") } {
        set count_filter [string range $msg 2 end-1];
        set data_filter "";
        set msg "";
      }
      set count [table keys -subtable $TABLE_LINK -count]
      set content {<html><head><title>Link Tracking</title>
        <style>
          a { color: blue; text-decoration:none; font-weight:bold;}
          a:hover { color: navy; font-weight:bold; }
          td { font-family: Tahoma, Arial, Helvetica; font-size: 12px; }
        </style>
        </head>
        <body>
        <table><tr><td valign='top'>
        <table border='1' cellpadding='5' cellspacing='0'>
        <tr><th colspan='2'>iRule Link TrackingControl Panel</th></tr>
        <tr><td align='right'><b>Table&nbsp;Name</b></td><td>}
      append content "$TABLE_LINK</td></tr>";
      append content "<tr><td align='right'><b>Link&nbsp;Count</b></td><td>$count</td></tr>"
      append content {<tr><td align='right' valign='top'><b>Controls</b></td>
        <td>
          <a href='/linkcleardata'>Clear Data</a>
          <a href='/linkclearfilters'>Clear Filters</a>
          <a href='/linkadmin'>Refresh</a>
        </td>
      </tr>}
      append content "<tr><td align='right' valign='top'><b>URI&nbsp;Filters</b></td><td>"
      foreach key [table keys -subtable $TABLE_FILTERS] {
        append content "\[<a href='/linkremovefilter/$key'>x</a>\] $key";
      }
      append content "</td></tr>";

      append content {<tr><td align='right'><b>Add&nbsp;Filter</b></td><td>
        <input type='text' id='new_filter' value='' size='15' 
          onkeydown="if (event.keyCode == 13) { window.location.assign('/linkaddfilter/' + encodeURI(getElementById('new_filter').value)) }"/>
        </td></tr>}

      if { "" != $msg } {
        append content "<tr><td align='right'>Message</td><td>$msg</td></tr>";
      }

      append content "</table></td><td valign='top' width='100%'>";

      append content "<table border='1' cellpadding='5' cellspacing='0' width='100%'>"
      append content "<tr><th colspan='2'>Link Metrics</th></tr>";
      append content "<tr><th width='100%'>URI</th><th>Count</th></tr>";

      append content {<tr><td align='left'>Filter&nbsp;Results&nbsp;}
      append content "<input type='text' id='data_filter' size='50' value='$data_filter'" 
      append content { onkeydown="if (event.keyCode == 13) { window.location.assign('/linkadmin/f(' + encodeURI(getElementById('data_filter').value) + ')') }"/> [<a href='/linkadmin'>x</a>]
        </td>}
      append content "<td nowrap='nowrap'><input type='text' id='count_filter' size='3' value='$count_filter'" 
      append content { onkeydown="if (event.keyCode == 13) { window.location.assign('/linkadmin/c(' + encodeURI(getElementById('count_filter').value) + ')') }"/> [<a href='/linkadmin'>x</a>]
        </td></tr>};

      foreach key [lsort -dictionary [table keys -subtable $TABLE_LINK]] {
        if { "" != $data_filter } {
          if { [string match $data_filter $key] } {
            set v [table lookup -subtable $TABLE_LINK $key];
            append content "<tr><td>\[<a href='/linkremovedata/$key'>x</a>\] $key</td><td>$v</td></tr>";
          }
        } elseif { "" != $count_filter } {
            set v [table lookup -subtable $TABLE_LINK $key];
            if { $v >= $count_filter } {
              append content "<tr><td>\[<a href='/linkremovedata/$key'>x</a>\] $key</td><td>$v</td></tr>";
            }
        } else {
          set v [table lookup -subtable $TABLE_LINK $key];
          append content "<tr><td>\[<a href='/linkremovedata/$key'>x</a>\] $key</td><td>$v</td></tr>";
        }
      }
      append content "</table></td></tr></table></body></html>";

      HTTP::respond 200 content $content;
    }

    "/linkcleardata" {
      table delete -subtable $TABLE_LINK -all;
      HTTP::redirect "http://[HTTP::host]/linkadmin/Link+Tracking+Cleared"
    }

    "/linkremovedata/*" {
      set val [string range [HTTP::uri] [string length "/linkremovedata/"] end]
      if { "" != $val } {
        table delete -subtable $TABLE_LINK $val;
      }
      HTTP::redirect "http://[HTTP::host]/linkadmin/Link+Deleted";
    }

    "/linkclearfilters" {
      table delete -subtable $TABLE_FILTERS -all;
      HTTP::redirect "http://[HTTP::host]/linkadmin/Link+Filters+Cleared"
    }

    "/linkaddfilter/*" {
      set f [string range [HTTP::uri] [string length "/linkaddfilter/"] end]
      if { "" != $f } {
        table add -subtable $TABLE_FILTERS $f 1 indefinite indefinite;
      }
      HTTP::redirect "http://[HTTP::host]/linkadmin/Filter+Added";
    }

    "/linkremovefilter/*" {
      set val [string range [HTTP::uri] [string length "/linkremovefilter/"] end]
      if { "" != $val } {
        table delete -subtable $TABLE_FILTERS $val;
      }
      HTTP::redirect "http://[HTTP::host]/linkadmin/Filter+Deleted";
    }

    default {
      set match 1;
      set c [table keys -subtable $TABLE_FILTERS -count]
      if { $c != 0 } {
        set match 0;
        foreach key [lsort [table keys -subtable $TABLE_FILTERS]] {
          set m [string match $key [HTTP::uri]];
          if { 1 == $m } {
            set match 1;
            break;
          }
        }
      }

      if { $match ==  1} {
        if { [table incr -subtable $TABLE_LINK -mustexist [HTTP::uri]] eq ""} {
          table set -subtable $TABLE_LINK [HTTP::uri] 1 indefinite indefinite;
        }
      }
    }
  }
}
}
