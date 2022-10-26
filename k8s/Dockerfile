FROM xiaojianzheng/python-37-centos7

RUN rm -f /etc/yum.repos.d/CentOS-Base.repo
COPY Centos-7.repo /etc/yum.repos.d/Centos-7.repo
COPY epel-7.repo /etc/yum.repos.d/epel-7.repo
RUN yum clean all && yum makecache && yum -y update

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN echo 'Asia/Shanghai' >/etc/timezone

RUN mkdir /root/.pip
COPY pip.conf /root/.pip/pip.conf
RUN ls /root/.pip/
RUN cat /root/.pip/pip.conf
RUN pip config list

RUN rm -f /usr/bin/python && ln -s /usr/local/python3/bin/python3.7 /usr/bin/python
RUN rm -f /usr/bin/pip && ln -s /usr/local/python3/bin/pip3 /usr/bin/pip
