var sysPath = require('path');

describe('Plugin', function() {
  var plugin;
  var fileName = 'app/styles/style.styl';

  beforeEach(function() {
    plugin = new Plugin({paths: {root: ''}});
  });

  it('should be an object', function() {
    expect(plugin).to.be.ok();
  });

  describe('#compile', function() {
    it('should has #compile method', function() {
      expect(plugin.compile).to.be.a(Function);
    });

    it('should compile and produce valid result', function(done) {
      var content = 'body\n  font: 12px Helvetica, Arial, sans-serif';
      var expected =  'body {\n  font: 12px Helvetica, Arial, sans-serif;\n}\n';

      plugin.compile(content, fileName, function(error, data) {
        expect(error).to.be(null);
        expect(data).to.equal(expected)
        done();
      });
    });
  });

  describe('getDependencies', function() {
    it('should output valid deps', function(done) {
      var content = "\
@import _invalid\n\
@import 'valid1'\n\
@import '__--valid2--'\n\
@import \"./valid3.styl\"\n\
@import '../../vendor/styles/valid4'\n\
@import 'nib'\n\
";

      var expected = [
        sysPath.join('app', 'styles', 'valid1.styl'),
        sysPath.join('app', 'styles', '__--valid2--.styl'),
        sysPath.join('app', 'styles', 'valid3.styl'),
        sysPath.join('vendor', 'styles', 'valid4.styl')
      ];
      
      plugin.getDependencies(content, fileName, function(error, dependencies) {
        expect(error).not.to.be.ok();
        expect(dependencies).to.eql(expected);
        done();
      });
    });
  });
});
