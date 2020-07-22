# run with wget -O- https://raw.githubusercontent.com/raisjn/rmHarmony/master/scripts/try_harmony.sh -q | sh -

function cleanup() {
  killall harmony
  systemctl restart xochitl
  echo "FINISHED"
  exit 0
}

trap cleanup EXIT
trap cleanup SIGINT

killall harmony
rm harmony-release.zip
wget https://github.com/raisjn/rmHarmony/releases/download/v0.0.1/release.zip -O harmony-release.zip
yes | unzip harmony-release.zip
./harmony/harmony