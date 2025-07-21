#!/bin/bash

set -e

OPENPLC_DIR="$(dirname "$(readlink -f "$0")")"
VENV_DIR="$OPENPLC_DIR/.venv"

cd "$OPENPLC_DIR"
git submodule update --init --recursive "$OPENPLC_DIR"

echo "Installing OpenPLC Editor"
echo "Please be patient. This may take a couple minutes..."
echo ""
echo "[INSTALLING DEPENDENCIES]"

# Update & install required packages (for Ubuntu/Debian)
apt-get -qq update
DEBIAN_FRONTEND=noninteractive apt-get install -yq \
    build-essential bison flex autoconf automake make git \
    libgtk-3-dev python3 python3-venv python3-dev \
    libxml2-dev libxslt-dev libgl1-mesa-dev libglu1-mesa-dev

echo ""
echo "[SETTING UP PYTHON VENV]"
python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/python" -m pip install --upgrade pip
"$VENV_DIR/bin/python" -m pip install \
    wheel jinja2 lxml future matplotlib zeroconf \
    pyserial pypubsub pyro5 attrdict3 wxPython

echo ""
echo "[COMPILING MATIEC]"
cd "$OPENPLC_DIR/matiec"
autoreconf -i
./configure
make -s
cp ./iec2c ../editor/arduino/bin/

echo ""
echo "[FINALIZING]"
cd "$OPENPLC_DIR"

cat > openplc_editor.sh <<EOF
#!/bin/bash
cd "$OPENPLC_DIR"
if [ -d "./new_editor" ]; then
    rm -Rf editor
    rm -Rf ./matiec/lib
    mv ./new_editor ./editor
    mv ./new_lib ./matiec/lib
fi
source "$VENV_DIR/bin/activate"
export GDK_BACKEND=x11
./.venv/bin/python3 ./editor/Beremiz.py
EOF

chmod +x ./openplc_editor.sh

mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/OpenPLC_Editor.desktop <<EOF
[Desktop Entry]
Name=OpenPLC Editor
Categories=Development;
Exec="$OPENPLC_DIR/openplc_editor.sh"
Icon=$OPENPLC_DIR/editor/images/brz.png
Type=Application
Terminal=false
EOF
