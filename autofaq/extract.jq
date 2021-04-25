def wewant: . | { text: .text, real_name: .user_profile.real_name, ts: .ts } ;
def replies(thread_ts): .[] | [if .thread_ts == thread_ts then { text: .text, real_name: .user_profile.real_name, ts: .ts } else empty end] ;

def fixname: if . == null then null else . / " " | if . | length == 0 then "" elif . | length == 1 then .[0] else .[0] + " " + .[1][0:1] end end ;

def formatline: .real_name + ":\n" + .text + "\n" ;

def strip_admins: if .real_name == "Drew" or .real_name == "Ashwini" or .real_name == "Mariah" or .real_name == "Akshay Ravikumar" or .real_name == "Anees Iqbal" or .real_name == "Tim Teitelbaum" then empty else . end ;

#. as $root | { replies: [$root[] | if .thread_ts == "1619319827.431300" then { text: .text, real_name: .user_profile.real_name, ts: .ts } else empty end] }

#. as $root | .[] | .ts as $thread_ts | { text: .text, real_name: .user_profile.real_name, replies: [$root[] | if .thread_ts == $thread_ts then { text: .text, real_name: .user_profile.real_name, ts: .ts } else empty end] } | if .replies | length == 0 then empty else . end

#. as $root | .[] | .ts as $thread_ts | { text: .text, real_name: .user_profile.real_name, replies: [$root[] | if .thread_ts == $thread_ts then { text: .text, real_name: .user_profile.real_name } else empty end][1:] } | if .replies | length == 0 then empty else . end

#. as $root | .[] | .ts as $thread_ts | { text: .text, real_name: .user_profile.real_name, replies: [$root[] | if .thread_ts == $thread_ts then { text: .text, real_name: .user_profile.real_name } else empty end][1:] } | if .replies | length == 0 then empty else . end | if .real_name == "Drew" or .real_name == "Ashwini" or .real_name == "Mariah" or .real_name == "Akshay Ravikumar" or .real_name == "Anees Iqbal" or .real_name == "Tim Teitelbaum" then empty else . end

#. as $root | .[] | .ts as $thread_ts | { text: .text, real_name: .user_profile.real_name | fixname, replies: [$root[] | if .thread_ts == $thread_ts then { text: .text, real_name: .user_profile.real_name | fixname } else empty end][1:] } | if .replies | length == 0 then empty else . end | strip_admins

#. as $root | .[] | .ts as $thread_ts | { text: .text, real_name: .user_profile.real_name | fixname, replies: [$root[] | if .thread_ts == $thread_ts then { text: .text, real_name: .user_profile.real_name | fixname } else empty end][1:] } | if .replies | length == 0 then empty else . end | strip_admins | [formatline, (.replies | .[] | formatline) ]

. as $root | .[] | .ts as $thread_ts | { text: .text, real_name: .user_profile.real_name | fixname, replies: [$root[] | if .thread_ts == $thread_ts then { text: .text, real_name: .user_profile.real_name | fixname } else empty end][1:] } | if .replies | length == 0 then empty else . end | strip_admins