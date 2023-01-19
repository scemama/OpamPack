#!/bin/bash
rm -rf _build
mkdir -p _build/opampack
cd _build/opampack

OPAM_PACK=$0
shift
USER_PACKAGES=$@
if [[ -z $USER_PACKAGES ]] ; then
    echo "Error: $OPAM_PACK [PACKAGE] ..."
    exit -1
fi

set -e # IN what follows, fail when an error is encountered

wget https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh

sh install.sh --download-only
mv opam-* opam
chmod +x opam
rm install.sh

git clone https://github.com/ocaml/opam-repository.git --depth=1

mkdir opamroot

export OPAMROOT=$PWD/opamroot

echo n \
    | ./opam init \
             --bare \
             --disable-sandboxing \
             --disable-shell-hook \
             --root=$PWD/opamroot \
             $PWD/opam-repository
eval $(./opam env)

./opam switch create --empty opampack
eval $(./opam env --switch=opampack)

PACKAGES=$(echo n \
               | ./opam install --dry-run $USER_PACKAGES \
               | awk '/install/ { print $3 }' \
        )

cd opam-repository
mv packages packages_old
mkdir packages
for p in $PACKAGES ; do
  mv packages_old/$p packages
done

rm -rf packages_old
rm -rf .git
cd ..

rm -rf opamroot
mkdir opamroot

export OPAMROOT=$PWD/opamroot

echo n \
    | ./opam init \
             --bare \
             --disable-sandboxing \
             --disable-shell-hook \
             --root=$PWD/opamroot \
             $PWD/opam-repository
eval $(./opam env)

./opam switch create --empty opampack
eval $(./opam env --switch=opampack)

./opam install -y --download-only $USER_PACKAGES

INSTALL_SCRIPT=install.sh

cat << EOF > $INSTALL_SCRIPT
#!/bin/bash
export OPAMROOT=\$PWD/opamroot
eval \$(./opam env --root=\$PWD/opamroot)
./opam install -y --assume-depexts $USER_PACKAGES
EOF
chmod +x $INSTALL_SCRIPT

cd ..  # back in _build
tar -zcvf opampack.tar.gz opampack
rm -rf opampack
