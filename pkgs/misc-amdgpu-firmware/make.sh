SRC="${HDX_SRC:-/hdxp/src/misc-amdgpu-firmware-src}"
TAG=20260622
BASE="https://gitlab.com/kernel-firmware/linux-firmware/-/raw/$TAG/amdgpu"
# the firmware the amdgpu driver asks for on AMD Stoney Ridge (a6-9220e and friends)
SUMS="fc3938a445fd744aab16523db079781afe0d064dcb416569a2c243fc256550ca  stoney_ce.bin
0812c914e5daad0d65ae04651dbe6448004ca726dd18e478bfc45f354b46e8fc  stoney_pfp.bin
ad9ff687fe0bf670620ff6317382583bb2240ce65a866c02edb24a8697e47493  stoney_me.bin
a1c84d90fbf5fcd0b8186b43c0246455dd8c66237ff6c2a03481276ac16fc49a  stoney_mec.bin
ab7d3f9c47d9763795d267a0d51722c89f5a2042aba232db575f4c86eb5638c6  stoney_rlc.bin
c23d03726ffdfb1fe253cfbfe36ab82ce5e69bede0d6c4157de71edb967a5fbb  stoney_sdma.bin
f7474c77bd185b6c2df3c7d24cb656e8e0edb24f1e296cb09447e3e41501a498  stoney_uvd.bin
e763aa4f281bc7b2f8b435bb95601e691cc1a7737c10aaa27e59a9b15e94cfdb  stoney_vce.bin"
mkdir -p "$SRC"
cd "$SRC"
FILES="$(printf '%s\n' "$SUMS" | awk '{print $2}')"
for f in $FILES; do
  [ -s "$f" ] || curl -fL -o "$f" "$BASE/$f"
done
printf '%s\n' "$SUMS" | sha256sum -c -
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU mkdir -p /lib/firmware/amdgpu
for f in $FILES; do
  $SU install -m 644 "$f" "/lib/firmware/amdgpu/$f"
done
