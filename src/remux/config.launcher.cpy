struct RMApp:
  string bin
  string which = "XBXA"
  string name
  string term
  string desc
  bool always_show = false

RMApp APP_XOCHITL      = %{
  .bin = "systemctl start xochitl",
  .which = "xochitl",
  .name = "Remarkable",
  .term = "systemctl stop xochitl; killall xochitl;",
  .always_show = true
}

RMApp APP_KOREADER     = %{
  .bin="/home/root/koreader/koreader.sh",
  .name="KOReader",
  .term="killall koreader"}

RMApp APP_FINGERTERM     = %{
  .bin="/home/root/apps/fingerterm",
  .name="FingerTerm",
  .term="killall fingerterm",
  }

RMApp APP_KEYWRITER     = %{
  .bin="/home/root/apps/keywriter",
  .name="KeyWriter",
  .term="killall keywriter",
}

RMApp APP_EDIT     = %{
  .bin="/home/root/apps/edit",
  .name="Edit",
  .term="killall edit",
}



vector<RMApp> APPS = %{
   APP_XOCHITL
  ,APP_KOREADER
  ,APP_FINGERTERM
  ,APP_KEYWRITER
  ,APP_EDIT
}
