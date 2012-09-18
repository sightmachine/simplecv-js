describe('Plugin', function() {
  var plugin;

  beforeEach(function() {
    plugin = new Plugin({});
  });

  it('should be an object', function() {
    expect(plugin).to.be.ok();
  });

  it('should has #compile method', function() {
    expect(plugin.compile).to.be.a(Function);
  });

  it('should compile and produce valid result', function(done) {
    var content = 'a = 1';
    var expected = '(function() {\n  var a;\n\n  a = 1;\n\n}).call(this);\n';

    plugin.compile(content, 'file.coffee', function(error, data) {
      expect(error).not.to.be.ok();
      expect(data).to.equal(expected)
      done();
    });
  });
});
