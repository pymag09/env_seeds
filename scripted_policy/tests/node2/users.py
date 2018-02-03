def test_users(host):
    assert host.user('node2_user').name == 'node2_user'
