#!/bin/bash

set -e

get_version() {
  sed -n 's/cardano-node=\(.*\)/\1/p' "$1"
}

get_revision() {
  sed -n 's/cardano-node.rev=\(.*\)/\1/p' "$1"
}

get_coverage() {
  if [ ! -e .cli_coverage ] || ! hash curl; then
    return
  fi
  url="$(./cli_coverage.py -i .cli_coverage/cli_coverage_* -o .cli_coverage/publish.out -b)"
  curl "$url" --output docs/cli_coverage_badge.svg
  cp .cli_coverage/publish.out docs/cli_coverage.json
  echo "<a href=\"cli_coverage.json\"><img src=\"cli_coverage_badge.svg\"></a><br/>"
}

get_git_tags() {
  local node_repo="${CARDANO_NODE_SOCKET_PATH%*/*}"
  if [ -z "$node_repo" ]; then
    echo "Unable to get path to cardano-node repo" >&2
    exit 1
  fi
  local curdir="$PWD"
  cd "$node_repo"
  # prepend number to log lines so the commits can be sorted
  git log --pretty=format:"%H %d" | nl -n rz -s ';' | sed "s/\([a-z0-9]*\)  (.*tag: \([1-9]\.[0-9.]*\).*)/\1 <em>(tag: \2)<\/em>/;s/ (.*//"
  cd "$curdir"
}

get_links() {
  local lsargs="$1"
  local dirpath="$2"
  local prepend="$3"
  local grep_file="$4"
  local report_line
  local report_name
  if [ -n "$prepend" ]; then
    prepend="${prepend}/"
  fi

  ls "$lsargs" "$dirpath" | sort -r | head -n 20 | while read filename; do
    # skip old reports and also *.md files
    if [[ "${filename}" =~ (assets|\.(html|md))$ ]]; then
      continue
    fi
    report_name="${filename#*/}"
    report_line=""
    numbering=""
    if [ -n "$grep_file" ]; then
      report_line="$(grep "$report_name" "$grep_file" || :)"
      numbering="${report_line%%;*};"
      report_line="${report_line#*;}"
    fi
    if [ -z "$report_line" ]; then
      report_line="$report_name"
    fi
    echo "${numbering}<a href=\"${prepend}${report_name}\">$report_line</a><br/>"
  done
}

reports_dir="$1"
allure_report_dir="$reports_dir"/allure-report
cardano_version="$(get_version "$reports_dir"/environment.properties)"
cardano_rev="$(get_revision "$reports_dir"/environment.properties)"
destdir=docs/allure_files/"$cardano_version"/"$cardano_rev"

get_git_tags > "$reports_dir"/.git_tags

if [ -z "$cardano_version" ] || [ -z "$cardano_rev" ]; then
  echo "Unable to get cardano version and/or revision" >&2
  exit 1
fi

mkdir -p "$destdir"
cp -a "$reports_dir"/environment.properties "$reports_dir"/*.json "$reports_dir"/*.txt "$destdir"

rm -rf "$allure_report_dir"
mkdir -p "$allure_report_dir"
cp -a "$destdir"/environment.properties "$allure_report_dir"
allure generate "$destdir" -o "$allure_report_dir" --clean

mkdir -p docs/reports/"$cardano_version"
rm -rf docs/reports/"$cardano_version"/"$cardano_rev"
cp -a "$allure_report_dir" docs/reports/"$cardano_version"/"$cardano_rev"
rm -f docs/reports/last.html

get_coverage > docs/index.md
echo "<h2>Test reports:</h2><p>" >> docs/index.md
get_links -1 docs/reports reports >> docs/index.md

# old reports
cat >> docs/index.md <<EoF
<br />
<h2>Old test reports:</h2>
<p>
<a href="reports/1599603767-f84554a61729c31e231e2d0dc600c086e4b0b403.html">08-Sep-2020 at 23:12:11 for 1.19.1-f84554</a><br/>
<a href="reports/1599151232-497afd7dedc5d5b9bdcdb0e3cac6a50bd9f7dd54.html">03-Sep-2020 at 17:43:31 for 1.19.1-497afd</a><br/>
<a href="reports/1599066750-497afd7dedc5d5b9bdcdb0e3cac6a50bd9f7dd54.html">02-Sep-2020 at 17:35:39 for 1.19.1-497afd</a><br/>
<a href="reports/1598996349-42dba1b1a3d8a0dccaeab473372c0f8929eff4df.html">01-Sep-2020 at 23:11:12 for 1.19.0-42dba1</a><br/>
<a href="reports/1598974193-4814003f14340d5a1fc02f3ac15437387a7ada9f.html">31-Aug-2020 at 18:29:51 for 1.19.0-481400</a><br/>
<a href="reports/1598599874-4814003f14340d5a1fc02f3ac15437387a7ada9f.html">28-Aug-2020 at 00:00:33 for 1.19.0-481400</a><br/>
<a href="reports/1598512522-4814003f14340d5a1fc02f3ac15437387a7ada9f.html">27-Aug-2020 at 01:05:35 for 1.19.0-481400</a><br/>
<a href="reports/1598459914-4814003f14340d5a1fc02f3ac15437387a7ada9f.html">26-Aug-2020 at 18:17:39 for 1.19.0-481400</a><br/>
<a href="reports/1598432978-4814003f14340d5a1fc02f3ac15437387a7ada9f.html">26-Aug-2020 at 00:52:47 for 1.19.0-481400</a><br/>
<a href="reports/1597867801-4814003f14340d5a1fc02f3ac15437387a7ada9f.html">19-Aug-2020 at 21:45:27 for 1.19.0-481400</a><br/>
<a href="reports/1597841496-a5300686e0f4f576b4de2eafbc05cfd03776cd6f.html">19-Aug-2020 at 14:48:26 for 1.19.0-a53006</a><br/>
<a href="reports/1597835983-9e06d6f9a293a9656bf6e31b7e5d0a9f498163d1.html">19-Aug-2020 at 13:11:08 for 1.18.0-9e06d6</a><br/>
<a href="reports/1597762643-9e06d6f9a293a9656bf6e31b7e5d0a9f498163d1.html">18-Aug-2020 at 16:49:03 for 1.18.0-9e06d6</a><br/>
<a href="reports/1597694741-a4b6dae699fa21dc3c025c8a83d1718475cb3afc.html">17-Aug-2020 at 17:47:53 for 1.18.1-a4b6da</a><br/>
<a href="reports/1597655559-a4b6dae699fa21dc3c025c8a83d1718475cb3afc.html">17-Aug-2020 at 01:58:11 for 1.18.1-a4b6da</a><br/>
<a href="reports/1597310771-a4b6dae699fa21dc3c025c8a83d1718475cb3afc.html">12-Aug-2020 at 20:17:45 for 1.18.1-a4b6da</a><br/>
EoF

echo "<h2>Reports for $cardano_version:</h2><p>" > docs/reports/"$cardano_version"/index.md
# sort and get rid of commit numbering before outputting lines to the file
get_links -1t docs/reports/"$cardano_version" "" "$reports_dir"/.git_tags | sort | sed "s/.*;//" >> docs/reports/"$cardano_version"/index.md

cat > docs/reports/last.html <<EoF
<head>
  <script>window.location.replace("${cardano_version}/${cardano_rev}");</script>
</head>
<body>
  last -> <a href="${cardano_version}/${cardano_rev}">${cardano_version}/${cardano_rev}</a>
</body>
EoF

remote="$(git remote | grep upstream || echo "origin")"
branch="test_reports"
echo "Push to ${remote}/${branch}? (Ctrl+C to abort)"
read

git fetch "$remote"
git checkout "$branch"
git pull "$remote" "$branch"
git add docs
git commit --no-verify -m "report for ${cardano_rev}"
git push "$remote" "$branch"
