# run with wget -O- https://raw.githubusercontent.com/rmkit-dev/rmkit/master/scripts/run/try_harmony.sh -q | bash -

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
wget https://github.com/rmkit-dev/rmkit/releases/download/v0.0.2/release.zip -O harmony-release.zip
yes | unzip harmony-release.zip
./apps/harmony.exe
