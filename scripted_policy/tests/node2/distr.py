def test_os_release(host):
    assert host.system_info.distribution == "ubuntu"
    assert host.system_info.codename == "xenial"
