def test_users(host):
    assert host.user('node1_user').name == 'node1_user'
