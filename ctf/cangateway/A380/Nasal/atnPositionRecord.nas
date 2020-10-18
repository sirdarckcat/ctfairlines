#
#   ATN Position Report model class
#
#
#   Copyright (C) 2009 Scott Hamilton
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

var atnPositionRecord = {
    new : func(lat, lon, alt, ias) {
        var me = {parents:[atnPositionRecord]};

        me.lat = lat;
        me.lon = lon;
        me.alt = alt;
        me.ias = ias;

        return me;
    },

    toJSON : func() {
      var str = "{\"posLat\": "~me.lat~", \"posLon\": "~me.lon~", \"altitudeMetres\": "~me.alt~", \"kias\": "~me.ias~"}";
      return str;
    },

}