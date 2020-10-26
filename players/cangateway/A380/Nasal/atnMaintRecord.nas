#
#   ATN Maintenance Report model class
#
#
#   Copyright (C) 2009 Scott Hamilton
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

var atnMaintRecord = {
    new : func(type, key, value) {
        var me = {parents:[atnMaintRecord]};

        me.type = type;
        me.key  = key;
        me.value = value;

        return me;
    },

    toJSON : func() {
      var str = "{\"type\": \""~me.type~"\", \"key\": \""~me.key~"\", \"value\": \""~me.value~"\"}";
      return str;
    },

}