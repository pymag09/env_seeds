def test_node1_dependacies(host):
    dep = ['mc', 'git', 'wget', 'jq']
    for pkg in dep:
        assert host.package(pkg).is_installed
