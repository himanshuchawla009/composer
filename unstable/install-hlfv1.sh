ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
export FABRIC_VERSION=hlfv11
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:0.17.0
docker tag hyperledger/composer-playground:0.17.0 hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv1/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� ��Z �=�r��r�Mr�A��)U*�}��V�Z$ Ey�,x�h��DR�%��;�$D�qE):�O8U���F�!���@^�3 ��Dٔh�]%�����tO�LP��&�C��j[	�ܭۖgV�ݖ��~@ ��d��K��'��(?��W 9$���(>B�=�+x��m��6>ӝ����J�؎n��hEZ�8��g�F�u�C(��:|��L�&�ߛ�E���,So�:�5�mb�Z'v��?4�j۲]�'�P��	k�:����Xv��VI{��#�s��&6z�F9x�r��/�P�[�BUr���!r�uP�Ǖ��/�Q�D4�#��;'�+��	��lW���eYa�1kl����_�$Q�*RT�b0�q9���s�'�Tt3R�N�s,��◟"��>��Mu-|�L�����݃b*�Fxwţg<����T�[�a�*�a�,��
&�?�}:��U�Ee!����0A�5�`��b�Ֆn���M	�M����O���KBt�����u��oc�	�|�Ա�{�����7���"���y���.9�x*��:�O~���DEaQ���l��Y[�h�X��\Ѯu��`W�6%:��Y6���a�[�t��t\��l��Tܶ�3X���k{�%��uײ��z�6�xj��u���$�6hJ�u��z$9�֬Vd�&�kY�����{nòYÆ�
J���FL�խ��4HH
��$ݎeW�{�4Tq�ˊaiM��u���X�G;ԡ��c��Nvͭx�Qa[k�g�a��6
��GM7
��5B@����N�61���t2D�bRJ��a��M�/t?K�A�zY0�ANb,�WJ@���Z,_ܲ��F����N��$ȥ��$K�����Ei������Q+�<S�:�좦n�Ud��uF � �3Mݬ�_�q���g�%���O�l
���B�qz�����6ϣw/(IT�ⷡ>JC�����Az�"0a#�g�������(s5*�F+�õK7�^���U�j�bQ�F뽢���w�5�k��A�A$�=棰>�0`�8�o����ưN9b�'���6ڗ���#���S�r�)�̤E�Α������(���f�e]�!C��K�G1�s(�4��cE����@n��]V��^��k�m@G�8�^)���;9� ��:]k �6�%�9����MN�b�M���	�}����g\@�k"ݤ�x�38N/�	�D�V��p�s-��+x���Bpʛ/^�j�#�]��z���s�҉�5�j�d�2�0a�����~)|��oL�G��<`���u����=�1E�Ed�?�AD%*��_��<���҃m�:����K�Zc�e�5v7m\�m4϶)P`�Xv�K���M��V����*�����j"A1��%0슁c��|9�|�BYb�r��ܬ�,�R�3�Rn����j`56���qW�Fw���a��D��i�-����p��4�"�V�G��Y�\�TV����\>�{P����I��
z�����ZFJo���j�dc�o�P����� ��y��'V��'�l���{$̶���uT K#�kU�ͣ�?H/�U�DZ��ɔ��w�BЭ0�`�]�@��h~|Z 
?:���h���������R�e5�f�ј���?QX������c^5���n9��&N'*�U҆��f[-t&�E%, x��M>�F_��>0L����ާ8M���0�������\���{�f���B�	b(�P��Qo!�}��}�u���`�������`,�� �ǟ�83͂i��?���/������:��\
���#ģ��?R4_��s����u�-�p�q�m�^Em[7��@���f�	s��3����u�p�ͳ	�S[�xl��~�}�(���D@���\v��h_?��;X4��:.i!cܳ�#���1�L�G��[�(TK��#�g`�NȔE��Й�aiؠ1R.��-�k�O�p?&	ZavB��a��ǐmR�^ձ�D~��iV���ce@>;s���?w�c0�z�^�iu���0�~pW�?˥�i�?u���߄�c�_�-��<`v��J�j�9j�=/qq�ץ�E�N8����^s�p Zz84��mB�u� �İ���k���5b�}L���#9�<�Q���}��*��\
�"�QY�%9
�@�e)�����t�D�aN����'`������^�Y�S8�x7��Q��^�c��5��A�e?�m�D��
��&
e�h��<]�~�g�Q�Պ�dz8�����8t7tȵR�l�����թ�����fhP��*~��~�
���!�Dq��Ǐ��|�N�c����=ck:�'��Y �J�����
6� H2�h�_�5�^�x�O���`����5���#����O(��E/Q�m�����v����{��S���`���@��.�(D������0��a9�z\P]1�w�p����ed~u���Ö]������6ТK�3A}?��&<X��;�����/B�@�n)���ck`�^֨ި�����Υi�.4(_�����"��BNT�+ƌ����C��y��9޸�%�B�m�uNjz=B�hbS��,�12�eϡ�
[5~��	�E����(�W�Uj�_�
k���ireMK�R�DE%�Vł��kq���q�X���{�ɥ2��\�v��I��MH!�n�;�(4X8���L�_Nf���N�\�l��pO(MEs�WF(Ԟ,�(�h��F�5�>�ѡ&6L�fc�(�O��w��9V�_a��gz��"L+�$��'�� d���!^%X"@�3��Ty���p_�O{W�o���i��"��I�"/�?�_���|6�m����@�	�ۻb�){�ח�	Tp�`��q�ߧM��c��0�����������0^���G~��>��Y�.85u�}�`���2�`�b�D�Q��v��tUNkOP *��eķ���k
�vC�7��\w�\���}��D��b��ǆ�-�|����\M��=�p<8q|���ba`�3��?+���>�% ��k����Ý������:��18�㒲���|����������:� ���A�Kc���(����p��-��{�ݷ�����������~l���g��,K���&j����JM���X���d)��,9&'*���a9�$b%��H�5EY��o�?ˍ^R����[��6��1"K��w�_��m������Lǲ]�k-���?pK�l���}���oF���7�}3������6����K��_,q�߿�&�� 篏lp^mg韖����q��F��	=��ϻ���Gއ��f�~T�����|���wW�R��/��/Jq�^e�LX���.��(�J]�
i}O��-�>-��L�������~�KL�7�����Ꭷ��<=/��z�9>nPf=�*�>�K~���($3���g�l.��3,�����R�������j'�T빢Z�v����n5���Z�㺕i��T�8�m��.N��v���PP���x�I6����y�B-&�C UN5�ʦѪD_y�(s�=U�<��>�<=����ZY�X2.����Ͳ��ǰʙ�D��"㝼n4*���II9�H��VZ�>N���
���Nk"fg���e�S8�I�rN�-�#�v�҄^�[��4Y��;���q�p3�yuxp�)��h�R�����u��ə�R����Q>���<_xkHY/�9�)��u�r����P;���������̗�lf]m���i�*��	�d2���~�,��Z�l�R��NfKrjr�[�>O��R9h�������Sō�����W�-s�yt7��c��ngq���J>~?iw�k�R<��{�؉��n�;ۧ�rr'��0�m5��$#�}:�[����}�U�'��ZF=U�|ʡ���:��|j[�%[�	���\2�ִ�;��v�C��û�������JقY��U��2��*��|� ��O���~쭙��?T��D^�	�(i�'���BJ��A�0q��F�zIَY�«n��Z�6��:�D�+�5_����wSr"~V-Ս�&��Bz��WWW�H8��e�wt��@:fH���~�S��!}[@E��w����۲�����J���Yuw�>��s�}s�)��?��QP ���s�!;)�@ۙc�����6�`MVo[���BSj�.���Nr��#	�Y�=�Nv�C�$�&��#�83�i�]��M�k�ɕRբ}�r�
�v��y�ũ��C��2��R�ɇ̓�~Q�*Y�(�[Ҧ^O5����ʻ���F�^w'�UH�$�+�z��W���ܽ�����_���S�"� ���P�E��|�?���M�f���Y�$nV���E�f���Y$nV����=�f���Y�#n�o���}Eq�_��'_�����7�l��W��M_��/���&��������w��ɥ�ݿl���ov]J���xiu_K����w�L6}���W��qD���{��c��͞d��Ѽ��k�0[L4,K�����N��5ݖ��u�G����Y/�pZ�ol;p�}�^���'���M�p��-�S�?���>�Sda��׹����]����y�e��H5T�i*6/�a�	���K���o�	�gy5���h������P�w��]���(�Ҥ��:���j4�wp�������d��L��xq�,�C_J}��)����B���A����u4_���nJ�/���F�D��E{U�auX*U5���������e�[�������O�^{�<�id�L�'5��N޺82s���z�>��^���(�{�q�M2���t9��n�"2<�hd:�΀��g���ڳټ
#��n��}�Q��a��i�e݇]��K�O!�ÚM �M�mwi�4�rm�8@;k� �K�vؽ}@u;��¨��dL�zZ$<܋g��`�O�FQ�U�`�	��B=<D'}f���x��T6�1^��s��ѻ������*���'8
�l� �Kvi�c�pW���G	���ح�_^�{���
�/&_]�	�MS��ڠ~��3lx�@�]�ms�4}H��@��:W�M�6�hg���{�ױ��{���nz���f0��o�{�;�b�4v�$N��:�JX���q\q�T��I�F�B���i@�A�@�CblaX ��ĂB�5�{���J}^��ꖦ��R��������{�9���v��n�~߲@�1�&�\�A�9w>��Dg�%�07�2�k�U=��`T<_�*ȍ���<;����s�W7�\
�9�T;�]�E�d $�tN�tiR�j�^�A7W̥!����TbZ�|Cͻ����+���'g���#"@��5�o��K�J�U<l!������G��\�A�(��X���M��#��͐�g���&g:�y,�|��G�7H�b�y#r;�1C800��h���� ��3g6�"�+�~��p�r><��{��`���O5��z����m�� �d0�=X�k��P�{�iȽ�a����po��}o%�����t��&��jș�'�����O>9|4�9rj�(��M���@��P([q�׃�l�HcYU�C�C��7�"�ݭ	�d}���6�~�b�^X����J&��������[y���d��ԏ�<�G��/Ϳ|o�ש����/4b�?���|���|���ا�}[b�q��7^|�ʽ��"�B�k�Ť�~�]*��$UMN�TRM��A%�TZQ�DVKѩ�BPY��eIZ�3*A�t_�dI5	�Ф{{�ۿ����y�3?�|�k?���n�3�GO�w����D�w�z{u}���[�ｵ�E�ߌ��M�"�����c_��ؿߏ}~?�������c�
������\��u��T�Lk�1K٢F�'-��V�OÓj�^�v����G�X��+�=��@��>3�{"ky��Q��۝���nbQY1�x�Y�'uZ<�� m���4L,��܊)y���1%�!���5�w'\���tG٥22b�����Ȼ��@�qi��*�Y�����wQ�~������!�i�Rh�:d��[�Q���N�ޝ�
�ذN��e�C{OX���H-����wiǕN;��X9����&�mj�����Fqo�`�U>_�7�Sw���H�J_�'\6���1�b�e��녑�dБx	���t
��?�sQf���rx��b&�L�N�^��c��m^/�?��S�t�uK�;��Լ.Y�rg<�&�Զ��  ���ӓ��:q؎�뢃-��^��Vj��O�������<�sB����<o7[N�)�3�|�����N��&�X�/f�f����p)5���������c/7�{~ҩ�?^J(M���P���#�hdٓ��T�	��/ϊ�K;k\�m��XaP�|у�D�ع����칞�ɸEPe��&����ȟ�AUK�ƉF!]�%,Y����c��m��;Y��`e�Er�**i��Q�1N���RT�%S݆k���є ��k�}���\�`��y��ZL/�d���e[|e�:���I�2s�r�^ZRnrP?u�?e�8��U���lJ#F��n�f[��w�z�X�I��!�aN`��ifΙ����B���H����W��D����~?7�gR#�*/��Ë���~�ދ��c�b���/�{�����������W/��Z����w�7}�y9�ȇ�B-��-c�^���ؽ��ގ����yM܇tދ���;���r��a�+�÷akQR��o���X�+��o<�S_}����ޏ����=L��KYYyX�*�e��d�U�6��^V�t�(��{gd�,=o���f �s�6��ܼ�X8ޥ!�#΅]Gk��8v�9ʹ0�u�]^�Y��ls�#�m�
�oTC���Җ��{��ص�Yօ�����4�uvE��Y*�*�q���?�c�T�j��숨TG	A���Q��5��)ZϞ\gѥ;�o��F��n�ҡEd\�Hb��� �Ĳ�	8�	��e��3S����@fZ��9�*��6��
�,���/����iG.X��-�\'ߴmF�W��!(�J��X�1�H[kG�����HH�Q�U��'h%^�GÖ�À��J՜$�:�'�v�(S�����pR��=A4���RH���R��AEY	�z��֨.��e>S���l�X�����.�["+򿼭 �W�a� s�� ��XHU,u�I|R�:��	��p�eŴ@��qa�{xrǮK��cH�?a:~���*msV/\M�c�%䪔\���m��5g��f�\#;[�U�\}<nj�r|o�6ꭉ�^������t�ƨ�%���.Ԙq�ȝ��
�jvN+��w�p��S�yOQΉ�x�r���`1z{�iK��(A�s��������XӉ=#�֩p��
%�n���0`Dyv�;�ԴB�P+�C��N�R3=/al�/�#��+��E�!��9�����0W4>��{������D��ru�ʔV�'Ϥ�ե4Q�� Y��X���񑑞�D�-�9)��J\��]Ab��$�|�?��u�`Ă��	v�-�@�`k=�Ba"��X LP�
]�^.P��q��:��&{v�l�x�F������p��l��&3�n�)�$�ړ&�l2�f��Y�LTRf�e
Is���,�L�D��@���C��[�t��c��+kD��u�4���މF.z�ʔX��8o(PXrP6��Щ]W3�V�LWb����3a�I�a5��
�5Zq�u��Nb&�WdS��Jt�8G�K������*gV���)�K�k���ط�� ���{-�����Po�z��Ze�r�P�쾯�64ۙީX�^����b?ws��=���D��{{ٶL+���9Vvz����bo�^������S❧O�0Ϸ��P�s�{=�2�����1�u�aʦ�z>����+z��+Q8N�coe{`�u��- h0��=�̰���_D��dG�4��l��������av{ßFU��mkv��=���m��G�ȣ�k�/eT�a/x��/�\���9�������D*y�������n��_(��}���}����G8g���;�a�x9�����������Ã$۷S(��'�Tirn��h<l�5h�g�����/�G�>���M��|[��كS}<��]'��;���?��p�U���a#��fY����ݞ�m�u����ֳ /�1��7�Az"fG#�w�f�� �14����ЛB�g��َǥ�%�gP�B����M�w�-=�AhS����j�PP��B��5���7��[��"=��&�q�1�3��x�,���X3S���Y�Sаˇg �Wg�x)3'������Z�VY��i��C�G��;H�]�ǟhsa���9�4T�?��>D�A�X�֓��ud�;�Lk�����ܘZc�=,�a��&p�u�H�*ň����z�A�LQ�'gL�VĚ����]�+�a%��@���w���<[�u�
,�N�C��qZ/��D�L ꆵ�1�����(�"�7�����Wr:!��D�c쒁�Bܣ+=�u�qG�ƽ�5���8��W� ������{�~�ADi~	] �Z��|����1Aafc���-:}�Td=����kX���O�o��#�� 1"XB�C[8�<�}ԋ���-�S��%%�Is��IB���t������EP�M�}�ǁ~<�e��5E�6qZ�J�T3�e�Z�i�iJ!#E�/(�dn.xf�A�%��Tn_ +���z.�w����}��Ȧ��P�e��ԯ«f����kJx������v1p�k�<�V���d�NW6� � 2 �"T�X����㤽	n�@=k�L-��2��&� ���h�����"/p�+���c4�� ��h��
����17y�C�������vX-�t� {c���W��`���쭣,�zmj�&薺n�a��,ί��W���"m]i_�b�V�&���>�	���7�a 8=6����kD�� Q�D�m �h�Wl=ag�B$~������H���B� �b䁮�<��@�$�!V?��T�J�>��)��Q����l�&A][l� ӏ���Md�5��^��U������5r�i����1�L����-�h�mx���ƚ�Zӡ�765�����@D�ݎ(�#��v�At����kExS���'����y��l��K���?�&�[�?�d���ǭ<~��}���(`�<�dG�%�W�`��W�3G<�{�y�m��s##=�kN/����;
6��!߀�* ���ػ���gy�|��׫���^X��y�zd�T�~�N)�,+t:Kj2�Ԓt?���zZ�P�}B�I%	�gIU�+�lJ���&�)F�E�^�r�Ca�����Xn@+��l���x�G 9y�B�^�;&$0�P[>H"++)ZV%AeiUV	R�z	9+�r*Ee�t"��hIYQa!9	F2�ը�F�)Y�?R��o��s��T/���m#-2\��=fpO��_�7���)��{r��dܵ.�Y~G�K(�/q5��68����W�S>.We��/?Q5e���MhJ|���l>I �*qnn��)4E^*V�'h������+ع?�����1e�Y�'����r�H�g� �D���U (����X��3qk��u���i/��`� \:;W�D8��A�p��w ���g�4��lϸm�	���C8 gk�!P�����~�f��(]�s��� T
�5�ol!:z�+2B%W��9=��x�U��z(��V*ғ��X���qx�:>����l��V��(~����c���E��v�h�����q��(Z�6�\��
�^jW"�ݓ�����v7+� oC�l&��A�1R�,���Ĳ��+��M	�#G�#1,���Yo����U[�"��}�ԃ�Ue��f��J��ߖP�G��;�O��ik�0�9I0�$
:yQ�H���S_�� ���l|7�����y�f�ȏ�n��^!�6�ƪ}�>ܹ���Q2� ;vKk?���& ��q�f��	w�#�=n5ʠ�����P|����c��g[:~1�oW�y���"�ER)���4x}���/8�gitGW����O����������}��O�i�n�o��J�������w��o�y�wL�'_'l��s�m��5�*y��o��*��Hl���;���m��y����=?��m�������w��������͝�;4��͗M���|%�?zG��;��V����45+�U`_Kd�tF% ����tOS�^6�!���kkN]�����ު�|��U�����nv"�(*(ʯ�4�L���$�� �y�U*�I�bֻ�sXo2�-Ȁ�Y�g).��yx^��>��M��$���?
��*�7���k����bњ��<ަ���{�5�{���9�F�q@gY8<�O��r�s�Fut�,F��m؅ҝ��C�D?O\�]�ڄs�>[x#<'�rv֒v�z��!�ˤ+�I�OS/�J������t�x4����}�x����u������?�C��
4��	�A����U�������?=���������Ͳ��U�f��Mj��|j �����8{_��_	��O���A �U������f�����������hu����i��J����@��
�U�pU'\�����)4B���?a��4@���� ��s�F�?}7��_���Z���i�~�� ��W����y������O������wC:[9�x��Yֲ��b���i�V?�����}ѻ��w?o����v?���|3��(���}��}"k����(s�u�RK�w7��~���Lq鼰��]��en,UG�%Y�B{�3'�nk�#˲�6N�/Nag�0�����{�/k�ȏ�}v�<ٳ�u�\9����o�G˔bN�:M/��v�X�����}J��
M�U.�<%�s��s	]���Zю��y �J��$�3M�f���r���r�i�3������m1:7�,�w+4B�A��64@�=-�B	������������,�������� �����+�?A��?A�S�����#@�U��,�`��.�����������+����U�Q������ ���a��>�:�o_������g�>�\X0���I<d��������W���}�[_���E����#����î�c[��'Ϊ����HJ�h���~�Q-���6gc}�Ǩ�/6��*��*�Q�K%/s�}w�,��L<�;,�:�c��=�z䯾>t�x����N��B�=[��(���
i�#/}�����/��RШ����<g�V�5ClC9���Z��� E��X��X�g�)��Dq�]�����Z �l���ť�t��7���������?�8�*� ��/Y�B��5 ����M����S���+A����q6X��<�|Ns�Oq4F�b!�s>\��1l@�~���$O�X��?�&��������W��ge��V�XL�h5$K3�t(��n#�-�TtWm}�����%��丹�=Q���W��1���\���vd�컇��<4O�6]n���gV��H�e����%L���訓����ͻ���V4������P���'���M8���ՇF�?��Ԇ��������f|B4����Շ_������GMi�����,�����g�?(�v庫���,=��?�O2e,EC4f=�1=~g�:Y�KdQXq Ig���6�2�8��3�Z����c˶&��)�`81�(��]��[ь��oMh��x����7�	�_��U`���`���������h�:��ǲw���A�U����[^�_�|��FTޑ/<n�l�,�J��gw���U-���0��ooGrU[˟� y��O��|�g�p��Ag�+�REn� �z�`�)5r4m����tK���{X �V�^���ەeɣ�TD+2F�>�Me�bi����A:�{Uo�a��v��ܠ@"�|��&ї�p��{z��� �i��.^��A���x���zÅ��hC�s����e~�b�A"��逴�A9Z�K���i.u�%��b�N���&$D�>���M��+��*c��]���^���L�q<[�j���b�S�l5���
y4�ҁ}�HFH�M�w�I��'\�EG'������ًM�8�@�Q����ǟ���E�����`�����&�?�=����%���!ӯ����4��V������������7�	����P���y�gh��}��0v��q"���=�c�Y�c������6�$�9Ǉ�ㅰ��ah��4��A�����_w�ץ�s��f��B�>1�Y6
ji��T�:��t�e����t)Ëe��JO�j�Ŏ�.wj#d�!��.��� #��9�L.c*]e���]�q�?9H<��� #7m��}+�p��ԃ���S	>��ou�J�ߡ�����?IA��
4�����?��U�j�ߛob�xo"������������_E����ۗ��vpCP��h�;�C��
���~�����o�8؎��e���K:e�TY'���wP�2�-����BK�gf�o�C~f����F�q��(&�d�{Zxܩ]����Α�΢�w�g���i���x�MVt��Kd2�{bw�_O�l2r3O��7���Y�uw���f�|8b\J�t�B[ٶ�����z��s����v#������zGVTE9���B��w+To08`R��c�Gw)�;�OeG��8�jJT��")�޷g!�y%OOxt�u[��ҡ��8Ř?Is4R#�֘tc�.�*;OQ�g�2�ݡ�������pFB�ǲ+C��U����5����7��?��k�8	��5�Z��A�	����7	�� �a��a�����>N��I%�F����M���ׇ����K�4����I���_����_������`��W>��?f�_Z��<F��=���_	��������
T������X�������?��]j���������?�`��%h �C8D� ����������G%h�C8Dը��4�����J ��� �����B#�~W������ ��!5�������n���"4��a-�4��?�� ��@��?@��?@��_M��!j��ϭ��������������(���� ��� ������+A�_G0�_��n����l������J�(������������a����������?�8�*� ��/Y�B��5 ����M�����P���8~�>�����#1n���"�|.�)�I�f���$�α����E��������h����&|���#u|u@��)����^��OT�`�w��f�aj��Z�|���c�§�љ$�)i�aP�4sK�#��at8I�����˶'��rLm�$m�a�P�s1G�n'!팻D'���d���!�*;�K_��X�	E}���Wkw���~��&����Yj>������	�?���������� ��w�����ߌO�&�?����+��0 u���v�nm�����Pꮆ�rԹ��m|x�/�N�z_���s�h%F�R��MKu'G�\L�bw��g��V��3;��a�)��ݹ#�{]Hb��Fj�Q�oWåB��ފf��w��C��"4���?������Є�/������_���_P��Wo�4`h�����?�����x���O��?���KǤ4��֚���ĉ�Y������j����n�N]���;�X"o��#w}���ڒOk~�PVw��#��S�\���X�f�`di'�ӏ&6ʨ��"mŬ���������#fG��h`{F�w���v���;}��{zt�m��t�b�����A���x��V����,0 <��F�04:��(�^�^(��H�8ĘHk���e����+��vٳ��yY_^ܟN}2��j1�9����:�V��v5!��tN�[��*>��Iޚ��F��n��=�F��������?���a�?��7���e(�b��9Ab,I@��
|������>�o����%h��é����]	>���)�F��*����?�p�W�&�?����_
��
T��Ϲ����<T������~_����U���aK�0�|��Ѝ���m�1{�q^�ϗ��u�
_���mY�^�?$��fiZt�+n��W��J��~��䇼�ޏ����gJ���[�ߗ.=]�^J��[��V���� �ƖLl���K�U�V]uQ,nuVoK��8Ф]+ck� CZK&�?(l�S�LXL�䚖Jٲw���53PZ����$����2)��)F�ryHq�����E�=��o�쥝�\k!F3��� ×������[fե���\��X�D����=����,�e�z'�kҭUH����=J���U�#�+Ȣ"�"���'�գM�|���x"��0���p� TB�!�Z�H���A=���3��m�B�sn����2�\l�&�5�������^��G���A��"T��X��|'=�]p�C��d�{�oSL�/0��f�X����L@X��b>���B���������_%����2-����a�'>�(��0�ý�:����iu1'��~����+ߪ�=r�V`������[���g��W���p���P����C������Z�c�������_�������?5�N;�š8�
;�2�EpW���j�A��2P��S��V`C�W�[�9��L��V�C�P����R����^�~���~&�V�K��e����Z�n�W&�3Cjr���7L�g�V���n�-F�6~d�N��]JȸŤ�nڽ(Vw��쇼���R�C��<_)7�(�Q,8�NK�X6�:�^P��E���t9�ٺ4�q�O���e=�v|�^:����p�R���jQ"��Q3۬�"@��o��A��2S^��R܆K*	[�i۟�����X�����]i��Ɩ�ί`������E�=hC*���~��E @BRO�o�DKmRwUo���DحbI��=73�M�3f?~��	I�ԥ�?(�7D`��Ui��,Id�,E�#~*1 ��02)g�,��PL�$C���-d6�A��Q<�����[P��H�-���ev�HP+2ry��b�\a��Ԇn{.�j�omXQ-�����˖P�`_*[P��K��0����q����I�${����� �����0���H �G�7���_�!b�?��@�A�AT��������2���ύ��a��n��֨���ޢU[����O_����7��Ы	�)����u�;�Z�1���$
�� �@��B��m��¶��m�sn���wۂ��p{�¾t��4r�헮��c�j�^q��V�e)���yv��n:�=sPl�k]�7o�Ԩ�uW��8߲��ߦS����9`�+��4&�o�?ڋq�dXyْ���5��,=��lg���k�B
/�����c���X���z��
b+�l^,65��[MZҋ��Z�k�70�U]�j��QBo)�u�T�������-��k��MP�A�<�u{�P�p�
&d4)X��q�P޴�]���|�Ζ�%m&�M���jm����B��[����~��_�$�?����h�O$����2r��
���n���G�?Ň(�MM������h�	��O4���D�?��?�����c�Q@"���׭����h�?>D��(\��,�����$@��P�7���C�ߑ������W�w��1D��?���	��G�D�?w��������ٴd��������Q�o$����~����?�����"�����"B����B�����c����/$��(��Gy!bBT��y� ���� �@�P��׋D�?�B�/���q�??�����_"�?s�����I������	��!��(�����?������(/D�@������4���(/DLH������h�?��(�����?�;�!���q�?���������׭�����h�W$H����q!�?����4����H��#X4���3��|��������/	��!����CDH��,E��P�܄��Mq�D�r�UM�h�, ��J���)9�ah@�.�,���^���$��=�����h���o��>t��jat��Ke^/�5�V��R�F���%Q<�
e�Dr�7�j�,�[ v��ye�G�[��2�p����)T��FM4�|8\ݭYZ�NQ�ʨ��R²���c]�4h�?��"�Thb�f�rE���6h5�b�gIK(����r��gEm+U�܌�;���;���<aH��G�?�C\�ߟ�Q�$ 	���!	����ć8��p����
�I���Ňo��	�^�J�b�I�C����
r*pA]�磆ȭ��t��:'��Z���z�;[(�k��eq� ��C�W$���g���r���5��j�IE��t�f��2��	5+�z�V��]�-"��H��Ϡ�ߘ��W�����D��B�_����/���P��1�� #���\�e��������ƽ�k�u�-:�n�m-�7K���?��+������b^(
��(3��O;۰��m<!�B�nZA0���߮�r��J�P�a��
�f�j� ��<B�`����$��E�J�mjY��'#��U>�U7n�)T�J^X�x������GY��<?�k�N�pxL�+腢�R��0�`$�^9|�y~��� )����'�
�<o�/�|%�@�IP�y����nW7��E���Z���%3��k��b����F�lFY� bR1�My^��𾸖٩e{t�ѧ��jòAC-r����v���|��G2(�S\����x ��PD����#.���������B���?
D���s�!�?�#����)�L�3��?
���aX��ʁ����O^��A�?� v��x�m������O_�����F�$�?�=������H�h�G@�Q�G����"�������_$�]�� c��_��K���bCb�-������$���������>�C��F�3��0��\{�N4�,�C�F����1�#`��a`�e���}�Gx1�kb?�����Ú�;��6Nq����eq����w�-aG�܊�J*�4Aq��rl����܂�7����)sA4�f�PY^\(@��R�o�4�e��n�(VtSr*�0��Ҹ�S�/v!�WV
��)�i��{Z)%�S��%{�K�f�;�1��l�W��q��9�YsXRȮ�[,�$�C�����	FI��Ŭ�X�ZSs��Zy�L�zR�u;��:�J�y'�n%Θ���D�?4�b���-^#�����_"���ǆ$���'�����/��"��$@��P�/����������OL�]��/wS�J ��u�D�?C ��		��G���D��h�lx��������?V��Z6|�kZ�l�R׻�a��/��|�?J��{��V����oOa
������ d�޲�[o]�iUeʨf����YήT�m�ѩI�N-�
�� /�I��Β��2��F-�7ҔZܔ3l�X�u����>�� ,�� ,�T@;��6/��<e�
�"%~����X��M�\ߣRF�˭����)-Q/���:�J����kYjNմxPX6�hC�U�����/F"�ya���+Į����%^'�����_�?C^���A����t��T9�i+�r.+�I�P(�!�VH��(��� C�!s��1*P8�5a�w��zd$��/�����G�o��g�s�����h�p;�_"v]�.��~����FE���ϥN�nS[{H��k=�:�\p�����J���Xi�H���Y��ד
�˚Tj��5+��)v�A9=�Msy:��&1m�C���K����ƇX��T��ʑ�������G�bC��\��q7ūD����[��`5Ӣ�,U�����-�B���o�b�j�Ҏ�~ky��؎�e���r'OWoW=O�y[0��o;�>3$2}N)S��d[�v�̭�T��()*mqd;ݜ۞�]sOn,�B��K��6���hd��@��_���1"�P�Wl@�_(����/����_��?Hƃ$�?�� ����P�����5T�X릖�R�t����u6�����1 �R�}Y vZ�a@j�{+y^`��,�R��9��x��v��ufA?W'�|�a�tF�����e�����L�����#�VUǫ(e2;N՗a>�����B�'�|Pnu���W����+�A�'��V�(5�i� v)` �"��{U'�-Y~O�d���7DC�3�7�Y���D�U'���𥙍���j2���H*����E�I�@�"}A)�d�])��SRE�_�Y�5e+T�����u5;������EF��<5�����>U1�jy��&��&3����������2��2���4$�G�O�,�!��s���W�~}4�oo�������ql�ǋ�Ж�wb����w�o�4y�p��	��v\[3� �oN� J�2������wV�0��~s�~]��7J���%��lY`~*Jt��qcw�P�����鷔�O��[���~g�������s��w�g��H�
��(��?i���?š�h����J+�g`�Oxac��m��z>\�v�״|\���/f![��_�5<'|����32�_+`|[,���ʒ�N�	K.�����Օ�X��t�Ѷ���R��՛_pu������޼�N�]��k�����?\�^���������&�?>��~뇯���`�����cn��9<-��A1+���7Ȱ	5���[�s0с��ܷ���3-U���ڡ�=<0 ǹ+�2-�C&s��7����so�˷��R���u��1���J�j� �O����y���7���^X���ב�� T��%nlW'���ͧ�q�Pĵ�_p����\�����N_M���>�K|V�b��Ǫ[��M�<��k����v�]�Ph��u�b�^�J{{vV�0Va��xX�����^�0Ӱ����[?Z�����?�5�4���A���A����� �CC@��Q�����R�h���?�e��?I@?���H�G����� x�X�{�/;`wh0|ل7��o�� ������=1�� ,�̄-+��*��{}0����y�|���.�kW��/}so�lh԰K���?���Ov���)Ͻ��\�4�	8V
7�<x��owa�o~y�������װ���rO��6�pud�U�K?^���<���������hv����z��;�gȚ�~s++���~�R9d�K.�zY{^��Nx�Cm|�C���� \�7�i�M<w�*�Y*��_r�ѝ��k�+՘(O��MD�/���;߄�����7�R#��gh�������3��?
<��G��N]xa7,Z5�:�e���GY{288ؘP��p���/)���k↤1S�X��s�?��uN[��;,��p����ק���~]��~K�����^���?�O������l�%N�?(0ľ��gQ�,��W^��D>�ok�WL�8읃5�������}i���s<�J������[��/�����D���
9T��$�3�5x\�i��`MEXdت,�&}�Ż�v8���n���i�75S��0����^h�?�pB/����L=���
_����=�\�v��C�u��4�����,��;��ᱺ먿��{�ʰ=߻x�����U�gO
��}��9��o��R�~��ǲB��2���_�\�\AA�k�^}�~�{�;�֧N�\�������:?�R<5��s�|��o��i޵�� �ʇ{2�}��3ðc�̻ja�����������9�}���>IҲ��c�P�l��ٻ�G��<�3�[3;�d�kvI�wf�����v��"M��.��.W�Q:3m���te���F�!�.����������Jp�� {`B�q��V� q��ȇ�.wUuMW�HT��e�#����?"�/�v4&�E�ct0$�(&�����@E#B�EE!&�4���t�~-\/`k�g�kRP}�&�B]F�h�gL?ē��Y���dUF��J#�\��n��K!�3Z�@[��P�A��G_|���霳:�w��,�g��]��
g� �c�W
*g[d���8��N�{4��S��lɲ�T-K[������>���?(�ë9��z7���S7��ky� ��׳�}ˁ��ZP�L�3���2{�:Fr��+Ϲ�s�k�ސ��*8O�)������b���ϵ<�����G�*��!׵�+�ݭϻ�7�3��˿�㞿����P�0:�����ky����S�y�L$���1����ߵ<�n����m�޼���?��O�����&£�P+ �t0m��H�1��j�b4�[� �2M�t���b!Z��Q�H�	��C��m���`�0�_��á���઎ �x�Q/m~�\��Ś2oo���7����[�D��ڸ������u�I�K���2��wa��O0ϗt^�x��*��/���"�R'�����{1�?�K�������8G�����ùt#����'�pf�u��7c�K��׫�4���x^H��>Ze��G;yE�5S��p�I[��}�
bW�	�PT�}r��=��Vѻghn�;dRn+�b9��/����A{�Φ1��xy�,���$�b�#zNW@{�,�5���.�p��O�60q���Qܪe�bU��>�E�(W�	�B�or�a�:�q�Y�w��wȬnZ�g�����³�_�v9���ۡ�t�v������~������5��Fdx-m���M��*mo�S������4��Q�I*9�G�C϶�#ϫ]��ao��8PU:>��ɰ�K~lK�M����� �C��
Q"��2ل�S�,�f�n��¬�D'��P%G��HI>��'#Ő��d���}��BY�������]�^t͞�Xe�C�2Pv1�i:��zP�>��H2R=���M`��3���H�ۣ�,�_�3��o{�m��'��=��<�:�Ȥ��>�[h[��v,�#����n;@fP�=�(H���9u>&���6����Mm��]����4e`�:#�`���W_S�#�#(7�t��7��W����t9Y ��Ђyֲ��g�ϯN��xu��v�d��@($ݐU�7������`����0cu��O�d`�����އ�+}�>9OڲK��I�#�ڡ�iw����-�qi_jBbKH>��>�C�э*d*M���*���!�4���i�. �d#ю`����ㇻK"XСd{����u
�����TDudB)���m�`�l�Vס�t�`����!wm�uX/����
jtH�&�>Q�(�ġ��uUUP�yE3����H{���p,ݨ��I�KX��n%������C���	��L���:�sW'KNԖf(��� ��7��ZcA���}�&�"�"�psW�E�g��[��}Vg��):X]��Q������I�2�����?�����{�_��揺?W!���>�ٿ�_�/��P�c
|�3����ڼ��c�W�*���WL�чt8I��	Gd���HK
Q19̄-��1�22��`�i�XP
�L�El�>��|:��ɗ~���?��O���'̏������ �N��� �o�W�h&��o�y{��o?x����[��q��WKĿ�#>�G��=�e'���;X�΀�)�	V�08�d�U�F��mK�Ų2c��xr����es6fL&5���+B�8�8P�M���fx\K5�xن̙�z0=�R�8n0=��k�SM>.څ�|��i|�Y����b	�� X���p8����;q/���ĵ�p���āC��a���)(dHM1����kޛ�
��� >�'������r��@ʟt��{f��X�����<��V��ՓC�Te�Ms�F%��o��<�.����d,g*�0��t�B�Oּ773��(�������������K�ٙ����١�C��N��,�$b�:٠����d �9f���������ow�'�3ߧ���=�޳��B��[`���|[����vgH'LIL��N���b�	�F�nU،e��V�V�Z}�ʵ(���Y�;�f��ϕ��&�*U����Lڋgf�QD�S}�|
TJ��hP�L�=rA�R�ج9�Q7}���l��<|-,tA~�6�$�|M�z\��q�b�6PZ��4���[H3\V1 W3�C��l��Lp�ZB�a��}�	΂tgό��x�������Ǒr|��1V8��J-�j�~�0�V��c�=HRUQ>Ҍ4��d�P�p&/�*�&��e:��^���,���Bc��$Y�E�Sl�ey*�q�r�O�\|`4�Q$��c��������pP�EN(�@"�`��҂0�Y�kF*tX>UOp�m�� �Ꜵj�2�1���j��H�c�֨Ocㄴ��:U� �
������PHq>U��!�-	e��c��T�Wس�⯃W�Y6H�A�3��?�+(U��uy�3;��Q����9.����f��N�s1;�8�� ��YL�Pl��K���:����(�;6\[�E�{n�\�s�m�K��d"�Qh淛T!d)�f�V{3u���X#�K-)h���������t�.���D�b�#�
�É.��r�|�\��<�'����v������x~T�*�-
lo>�Ĉą'�n����g~�lvLǊ�ұ�Lh��L�f������F'�̘���RL?��G�;N��l?(�2ŃC%\o֋�XR����v;1GÃ�R���y��?�q�x�� ����7^�|��:ޟW �8�x	���b%���[N 5FZ��Ò�*���xm�eb��}�='ߞs^��Pz�[�൛ 6 /����<�U���w�8���;Ŀ�	|�\�O���c�}��=���߽�����\U��# qaa�9+:.�L%^�7f�T�r���)�/ԮHR���J�� �Hs�ˁ��=�>�$�\� �G|��j� �z(�b ��bU����Jg#�p"��NKr�W�p�n��؀*�u��V�RS9�a61hɢ9�L�i�f�h�1?�s��~8�,���� ���|��ٽ���ۙ���v$b	�j��,y��������X �*G�_:ʴ�Z�>R��|��GE�AtLk�l������[Eu0��6�׍kr�V���X�7�^��9^��3.���l�ƹB�@�r�s��ǹ=����(�OE�E�3�V�������:�\��_u��s��u���B׵����8}���B|�xV�f�dVPu���iI/mr�K�]q��wW���{������VC�33������B�d�J#]��A-�K��Y�ɲ�U�B~o��P���ܘ��I�+y�jN*�f�����2Wb�������6\=>)���Ƅ�,R~$�u@����g�N�Ds�tv:���v��=9�k:^�`�~�v��)��d���.���(Z�3�C9�m�kui��U#�����d �4�TvZ�Ԡ�t�5:��f��DV�R�-j����ƺT?��Z����ܼ�+����2q�F��7Rܼ��L�7��K߀>��/}�x��y����x�2���|�B������Vd�2�T��p3n��*�͕5sd�fC��K�����{Y��W�%v��\&�"^� w�>}J���)���x�ٷ]�׉W���"��x��
�"�1��%
�Ѥ�F�z��>��̮�uX��CB�r큣2�v�v$Kp
T����]���y��΁��ఒdȦ)�Cl�w���̵���+�%����Y�˜��h�
���9��p(�r�G3�������?W��������Iҹy�|�!�J�-��K�n����0Z2)c<�����&�Nt��I	&9a [�������t]Eվ�v9-2�p��ॻ�����H@Ϸ��O>r~I�Q�R�%���$��G���W�1�r�Ӈ��I�S�W�ȹ꾿���5�z�|W@�t���Kwd��&u�	�_�Û�5$�P�Bz��=,���E�B��v� �)���7d\H��`�L+�o����W1�W�ٍ�~��k����c$G��x�,Ν��,���#U"5�,�(���S��K#��Z#��8���"Z�V��	gO���5"q�t揟]ġ �>���kt���=u��vpP�XV�!���b���Y��G���qI��P#��z��',f=��H�L~�kR1��V��l�ϡ`u��9�M������I���Ҩ�9�3X��F"0�.�̋^t��=%�|Ò�h�2�}��C�|���*`1��9�H�\z �18��/ |s�G�.��8�&vu];XѰ��?-�@rcS1�;��������@b覉F����_[i����Et:��8z��9�Z�����F�x77�gX<��C�ZK����g į���")H��Y�T���k@��'�_D��?���?�L�.���r�aM�\�2dG�.���6���)r��;��I&����2�"�e$��{��~o�3]=��Vfo�}�-ӻ��}�;u��k@Y캽%�Bv����]��A:�6�� Eyb�����-���Q�Ȅ
d��t�{!�d�\��6R���Y���+���2��԰d�)`���#�i,YaJ�vY��@�*��`]��P6�)(~��=Vn�ԡ�!���-��#h�Q��;��+7�t�-�!\�;�گ���EPa����v*Ω��T��|��]	{_�b�
{C��ɺɤ�N[����(���q$:��Ph|���,�m[���E�0T�<pz� �ɾ�渡��y�c�4�t��l�?�	�-��V��*k�}Mr�}6��ֲo�ֵ���`d7 �Q��@,����y�k䲨���6[H�JSr���l"
�n1�y7��g�dk�}Go,{�/\9����S �����
�|݊�����u��<���i����8��?�0�<�:���37���8����� @S@m�d���+1���s ��B���⾵�A��l�O�~�G֙�k
�{W֜(�u��O}7߅�6��Tu�ˤ�oRL⌊���_ѤӉ$�$�;{]��	Q�k��:�bv3��N/��/wu�������׋���gw�V'�6J�0���;_�_�5��-q��W��y�㮔O����S���y�ah�q��0ֳ=��)�y۶��}��'m����I��8ާX�ۿ���Tv��{������w1�ݝD����r}{���k��������W���i왡Lɩ�r�+��%c�g�pݔ�4+���B��V�Ԕ�R����6x�0�j)� ˦bY߱����=:��R-]iU���s���C�j-冺�I��v�ϟ�$�t������vt�昺��݅>'��H��0��KRh�ܠA�$��h���x3�:�9u=f�o�{׆�>��.�T��L���z�����j4e>&��]�^�ӻ�g�������[_<;���&{E5*���L��索�R]~8�roȊخ<>���*�ܨ�F��v1����h҄���5��.�tǷ��y��{�if��Z�����zλ<�lr]�NZ�[��.������MM?����������o���d�ze����iA�+���Z�Y���,�Q���R�߇,�p�ToKUY�;����_���Bh��~������s5���޹���о������ǃ����-ҟ��L�ϩ�����$<'.��ɖ� O����{6�H���ί��K�E��f�y����	)�ώ����q/��K�Ѥ�|2&c
-��m۬��꩹�G��O�)�ɧ���;|����@���y_������>:��<t�o#X�?���z�c�I���L�����.��x���S��<�O��p�x40g����>��<�����p��q���E��f��G�|��w�?���
���(�8���i���������� y_��������ߓ�#����`�7�8Ѐ�ou����~
��.�����_&�L��o�����qؐ�<�D�yΐ�]߳]��p�g8��.I���R��`��S���F�5=�4���~����7�����{�GS����REx�,R�`��h�f3����x�/�Y�VWH���Ъ>��j�n�d���}g��#SH�AL�������١R���E���f6@��к\{<��C��7�}��ݩ�����dt��hV�:$����=^H�%:���W'��/�����~Ȁ�/�/y�( Y��������	����������@f��L�c�������?����0��,�7�'��y_���������\����P�?�'�@�%�������?�^��?���F���*�̐��T�I�5�3���`�Nت����K8?�B�?<%�����ϵ!���m�W����?��3B���C�G����$I����k�3������O�Ʃ�8�]��n��OG�v,^�s��tu1���l%���Gz?��!zUw�g������3�+��YeDٿ�����6	��27�F%���ĹW[��)z�V�e��Ǎ1R��r���P��4�f�4u�ѱ\6v��w~�l3���z��}�'�ϊ����H	��Fٶ����#�:��k���P�/���rE=��)�t֞lľ����܌>�Ƶ6�.KJ�<W���6��Jo�i��u���*N�-�U�o�kM]�-iu�Y�ߖ4(������P�wn�@.���k�B�?��熂�?�De�B��)�O$� �'��'��w�?E�����@�_4��?'@����_!��f��������� ��<!������j���;�kO�vq#BӚ�q�i���x������K\�ǃn�Kχ��k���F��dKJ�!��3�CS�����4W�\�¦�\��7�:X���J1USE5�q����bU�2C����s���dCW�sX�<��}A�s\�\z$]b��OD����h�_���e|��fS	5&�G�H�k�&7S�X�r�/����gעA�ZQ�
f	c��ړL�=�(%��4bҀ���G��K�͇�37���P����O��,P�7��&\��g�����+��D��#��g�B�7tp�Ҹ�b���P��<���O9�ú.�$C����b�˸4ɓ�c�G��Q�O����?�N���Xh��Xh5$
#n�>���\�K�.�N�zo8�����q���Q�h�(�m����>H�-.-+HT���}��s�h� %'Z�r�X�۵�8���,р*���ܫ�W��_E������~�of��'�����/?����'7��/o���}5��������m����jJi��l`!ہ9d�%ϴ����.&��ĥ-?
���R#��ґ�:fm�17�Ҹ���!�����P�4�� "�](�;V�0���p[jY�y�đ��6�(��h��~�x�����	Ex���7w�7^�? E������ �_���_����9�@�B�S��T�Q4�,��O�/`����H��o�=���qe���W���$��������f�����#{  �~` �g=���I����̝�JI6xu �������Tۄ�v���C�Q*��v���bbY�Y��.Q
�Sc���x%�6nlG^K����[s=��b>	n��f���w������WJ� h��b���x`-JY<�OD��u��h4|��눲�������s$P9���I�T[�t)�t 4�#],I�8��8}�		{��wp]iJ���0m�]�Q���]���kUq<�e��@Bf�Zu�e4�ׄ�8�yԷ�z� ��0��C�Ju7+����^4p�{��n��P(v�A�N��?���<�]*<
�,����?,�����#��	,e���3A6��~EEV��V��?2����?������O���l���Cێ�`�����O���۶�0��p>i;^�h��q�O�>n3�����"��i���/����A��N��M��A�@�Ct:������ud�
��W�k���[J�`YGj���2���*�+�&���b}9���^#�Q�>�:&���8P������6�׺k���ֺ���2���*��������7d����Cާ	xY��{����,P�g���P��2�ۛ��㽀 ��ϛ�	�*��?#d��B��a9�Ȋ������g�W�ߓ�_Wz��6��E�(<T��;��yU��s������[!�����g�Gj���l����8�6�����B�J�8@^���l9m/6��to��NX۱Fo�׺z��#�k�n��6�vؙ��mM�ʶg�Ǵ���2�9�b�H�&3��C%��I�%�t�� �Z�|�zOƶȿP�-��{ˊ��#k�6���j9�|W���5&�}L��Uʶ��Uف�+mImJT�5DR�����gy�ˣ�Š��*�[�n;��;�C5�h�	����ˡ��5�yvk!��^m��� Q<��)�,;3A���}���	�?�߽����k�"�?�S��9!c��B����Z�7�A����꿡��a���'��,�@����E�X������[��������'��/����/������������<��Q�y�( Y��{���LP�'����)��,������c!g �������w^ț��"_ �����O��Y���&(��9D~ ��ϝ���_��#���"cd��o����!���?���]��!B��)�_���E��� ������O_� �g�"�?��d�"��i��?d� �� �X�����s�� ������X���0�����S�(���� ��� ������?��E��8���� ����������?����?k!����� ��P���t�!B��)�� �������!ڄk�������E��H����LP(���t0�e�!��qC���.�p.O�O�4�y6���8�ڼ�����E���gM�E���!��	?��S�"�4��W���Sx)+Xl'��f3�05��D-��x�0Ƞ.t0��F�;��fe�w���\ۑ)� ��5ۆ����cٖ�ұCͥYXr� �:���i��<��v�JTƁ4�.�a�m�	��]���CM��0��(ԥ������C������~�of��'�����/?����'7��/o���}5��������5\R���M��Km�lJ��/U'�hVNY���AX*�.�k�Ӎ��f����^�To<���ao�!�vi�����eu���[�Y��㨿�W�Uc�ˍ:I,Q?�HM�ʫŤ1Rh�_E1��W��C�7#��������xq� ������A��A��@����
��0"5����������*?��xvH�+����kF�'��_������m�H;Y��
�t��:��?rYk��˖���ݔ_1�U�/� ����Ϊ;V��皖��+���`fDu5��	3�����aƵ�YRGʬ�l#�+a�\k�npw�����II��]c]<ͅ�(e��鄉�#�6�	[��A���ʮ#��7�_<����W'�zdPm-�np]iJj��;�/��;��C�9O��讃����`hm�|�R�4a,�f�#�_�C���lS�x��e�G��튜��ŒfW��o��G�?\{���#��{�}���gX��||��?�����O8�&(B�w����	�~��ݠī��b����,I�g�"�?q������3AF���O��!+����������,�Z��hI���?tc7o.�1��q^�y#�ԯV�bG���eY���?$��biW.7��R�k�3��~����C޻��}�y��5c%�[�7OS��.��K3I]&��ĵ�ٶ��Zb��eZU�!몋b��Y7���,E��j(H��fݹ¯�
6]*R$��4-5 �c�����[}��M7�Y����+V]ӿ�W8�]��7�E6����MW�uj*�MPԮ�����D�9��n���$Y��y��]&�XsO�n�@��7(��FL�2EK�]yg�:�N��mMXk.d���_�~�y�Q�Hi���L,yKqX�����h[����?%��"?Q,y7��2��·�Z�;��^f��dxV`��ΐfQ�	E;�Pb9�2�3��}f�A���V-�b�1����0Gv��%�<��	Y0����b�O��������wE)�q��sBN���D#њ�Q&��Z7k:���qR���� �i�^��j��H��C������dv��`�߉��@�_>����<i�Ls菉��	�e8�h�����A#��d.1{�����r�Z��G�dj���o������?���\P��R�����\���<�E^����?���w������[���)�����RL�{��a�������\����O���ӓ�s@��g�_�`���������_���^���u����׻���n?�u~?���æ�F�ڑ)W��o4V
T'��t�Z�=���I�7����N��I��4C�1���hsz�y�r�@�dn?�{�~W�t��j��sX�fl�UnR��X7[F�G~�n�)#��'����1��8��3QCG���&(22f���R�BV"o=Nt���� ��Da��w��b﷧�J�a]�C8<J�����~W�A�a��?��SN�c�'TR�u��i��4�eS~:�~"(�05�PQ�V���
�%����D���5��{;�������/'�H�_�Iz����6�t�s�mU� 
>���HNo:����˖L�@�+[���(������?��<����x.�$��<��w�����������Y��{���j��:���������_qț�/e`�tpY�����/r��Q����5��e�_���_��K��S:�v[�۽��ك��/���2�ҵ�K�˾��3��}彮}-�}� f�?j~~쮄c�_��&]&]���%��о�\C�;u}���έkW����:¸�֦�N_W�zY��$�N�e9�F?�[��o����v�ɂW|ht�pu=u�q`LO�5�C�mċd�-�(A�[E�3>�p�5��2�p��v;Bt����t����U���:��.�+�Si�XS��!6���%��<�-��U���mY���-c�[ibq�ܹ)�7Lw8P$�騻�>�����rs���� ���5SJ<u����`0b��G8-6Es�5I�S��I,�6���F�Blh��3�o��(��K�J�Wr��
�������������[qȕ�A x�P
��6���_����� �������L��k@ @����e�0�_��P�\(����c���P���A�G���7�/���>M�� ���=�?F�?��������oNȉ�o����P ��_<�߉��?���.D) �����5{������\P(�����?�������	������.D1ȋ��t���P�� �����/�����?�R8�������_�S���R�?�)�������?������ �?����r��.D� ��c�R�?��/e�P�����W����P�� �@��b��;�@��\P�����`�?��+��w�?���\P�����?��/ �������E)�B����P��[�(ބ0���[����k�����r�Nb(j M-	U��E.5���n�K�F�A���n�Z]M�����F"$�!z�g�gG��F��� �?����i��E��0���b����vD������_��ω�dE$Q3߀�X$y���^;��96��J�F�Us�V0��=��p��ɦ�G��u1�(��U��n�t/,������r�RƑ=LT���֙*}�!�$��¯��`0͙G������'{�椊��%C�P��86��.��-�0���8���A�Oq(��/�����E_��E����G��ju0q���)<c(�Zդ��4�Z�;�q�.n�v�|x��Z�d�[v{�����f�l���F��;(�h�wktc��Q�fM��-s��U�A����^nW��W��Z-��E�:����Z�b�Gp��-�������?�U��A)�@�Wa �_ ����/����(�Ѐš�� o�	�_�f�����}����� �6���NQ`���������O�ȳv!���f�Ё��Kg���� �v6��B �.���n7SU�,{�?�R4��ՙ�L�[*B�%t�n�z*�6���u�m;��j���x:j�>!�V�n;~Qg�p��V6��,�Zn8.��
YKh��Ο��9�*�fv�y�G�$)IE_]��d�q�Wj���z���T�5G`P�t�:��GQE���Y�T�Wm��y��I�vy�ӱ�AR�>V�(	���(�v�1�&�&�$��tQ{̓��?��{�2�?� �������`�r"�����?�N�
�?rA)�����B��y ?����
���E�?����"��b�?K+�
<6 ��/���;�?������M���������&��D��'���A�ܑ�����(�����#���?>.J���;�_������d� ��c�R�?��P�����c(��O���b��G.�f��)��P?�H1��"����cW�3ri�7��(��=i(��	q���+����]�s?���J�G���"�w�a�����5���ހ^���Ԝx�T��hR;�#�*��J��d��[˺�v{"i�f����i�:�p�f�Q &�a�3mNO3�![�ȓ,��޼�k�/t'�WՄ��l9���ܤJQ�*n��d���1��SF��OL����83���D�cϛ��ȘQ�z�㸭��D�z��P+�kG�)���6�6����oO���ú�q�px�({�8�R�?0�_��/��}1��l�W
�����T��� y�����_��c> ��@�/P���*��'��OA(^�}j^��xD ����_)��@��2���-���Q
����o��<������(o��Vӎ����D�Z��l�S��7�>��$�uuOt��7puor��)�Q ����9 �>�6��c������-Z�U&��,/Aoؑ�y�VUI�~C��Q�G�S��0�7�����P_�%�=!�� eI % ʒ �(`�0ɀ��i˭�u!`Tb�|�ZچH�2��R��ڍ����{��)��Q��ñ܌�!��*�W:l'fh$Y���t��z3��Q
�����?9�x���	xї�!����e��z[��rA���㔮�(�$U]�Ӫ��!f�F�J`&�!t� P�DT
1MB74�4�4�-I�C�V�O�2����� �?����#jAܧ��|P'h""��U��d0�f�AO6�c׫�����q3���ު�A�
abu��B⚐;�j����2y���:��r�Dᴜ6�E2L3d�� >����@��ע�?��Y���&PE_��F�`��R�?��)���s��,�Z<"�����+?���;wj�Z_�Yx�@<�������n;nt1el����j��C�Hlǣ-���;wa.Aۭ)�q(L�R�PZ��c�?�j�0���'j:�S� (8z�����c��{-�1�����<P�����pq(E���* ����/���?@�����A�D迂�-�7����}�m[ȩ��0VEV�x�E����{����#���� @�F /s �k+ک�@�[UU��CU�L�����TM_�cR|�Ck���4Ir8G�W�����<j����5QzQ�n{������s�e:�U���<�<�|�R+���2n2I��DF7ؤ�}�/ �K0PK��ƭ��E?k2-H������ь!	qǳHɗ/X.=��4J��b&��C|.��R���'�}Q8��ИՄ���M��:GMēo�+R���ѵǮ927�d���6�s�>ZGz=n������m��\X�r<�hm^G����{��m�˧��1����(�9�c8���p�-ï��P������ק�����ꥌz6a\i0�@�>p�C�5��?��v�!��� ܘ�kT���wQ
b�3�U�ovq��Yw��+O���e������=r����{���?/^�T�,L�����W������}c����^��q^���7�1�����F�`�/��?`��aM�l�[E88qe�WL'����� t����n��x�����Ȉ+�}�ވ=]��FN�i3����k�^J'޿�=���Ubۨ�04��-�0�z!^���T�e%�']q��_~c�a�ð7p��"���������� Y��ҽB������w�v���dW�)�dpYWyo�n����sӯ%���.��_fg���u57a�y��5��V.oS%�T�/W����j���y��Q%�S�w���V�M�-�x�Yq�hgT>'���>�����~�oW�_�w�f�������۽m�"�0���M��B����L��sN���+�a���&�З6�y�u��~���M�;�(�@R�������۟.|�|v����vH�qO�������z�C_:�>��6$�<��D����2Ҽ�.��޽�¬��}�}y���`��?=�OO9F��F�(�`�� ��M  