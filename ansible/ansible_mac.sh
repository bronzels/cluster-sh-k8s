#为ansible安装python2
brew install python2

#为ansible安装sshpass
cat <<EOF > sshpass.rb
require 'formula'

class Sshpass < Formula
  url 'http://sourceforge.net/projects/sshpass/files/sshpass/1.06/sshpass-1.06.tar.gz'
  homepage 'http://sourceforge.net/projects/sshpass'
  sha256 'c6324fcee608b99a58f9870157dfa754837f8c48be3df0f5e2f3accf145dee60'

  def install
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make install"
  end

  def test
    system "sshpass"
  end
end
EOF
brew install sshpass.rb

#mac
brew install ansible
sudo mkdir /etc/ansible
sudo cp cluster-sh-k8s/ansible/ansible.cfg /etc/ansible
cat <<EOF > hosts
dtpct ansible_ssh_user=root ansible_ssh_pass=asdf
mdubu ansible_ssh_user=root ansible_ssh_pass=root
mdlapubu ansible_ssh_user=root ansible_ssh_pass=asdf

[all]
dtpct
mdubu
mdlapubu

[master]
dtpct

[slave]
mdubu
mdlapubu

EOF
sudo mv hosts /etc/ansible/
