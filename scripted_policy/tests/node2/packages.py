def test_node1_dependacies(host):
    dep = ['mc', 'git', 'wget', 'htop']
    for pkg in dep:
        assert host.package(pkg).is_installed
