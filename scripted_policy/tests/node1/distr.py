def test_distr(host):
    assert host.system_info.distribution == 'ubuntu'
    assert host.system_info.codename == 'xenial'
