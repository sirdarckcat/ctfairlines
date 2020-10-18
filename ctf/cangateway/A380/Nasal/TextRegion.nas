#
#   Simple utility to manage an array of text lines in a region.
#
#
#   Copyright (C) 2010 Scott Hamilton
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

var TextRegion = {
    new : func(lines, width, prefix){
        var me = {parents:[TextRegion]};

        me.posLine = 0;
        me.baseNode = props.globals.getNode(prefix,1);
        me.maxWidth = width;
        me.maxLines = lines;
        for(var p = 0; p != lines; p=p+1) {
          var lineNode = me.baseNode.getNode("line["~p~"]",1);
          var redNode  = me.baseNode.getNode("red["~p~"]",1);
          var greenNode  = me.baseNode.getNode("green["~p~"]",1);
          var blueNode  = me.baseNode.getNode("blue["~p~"]",1);
          lineNode.setValue("");
          redNode.setValue(0.1);
          greenNode.setValue(0.8);
          blueNode.setValue(0.1);
        }

        return me;
    },

   #
   # append some text in default colour
   #
   append : func(text) {
     me.appendStyle(text, 0.1, 0.8, 0.1);
   },

   #
   # append some text to the region and set the colour
   #
   appendStyle : func(text, red, green, blue) {
     var lineNode = me.baseNode.getNode("line["~me.posLine~"]",1);
     var redNode  = me.baseNode.getNode("red["~me.posLine~"]",1);
     var greenNode  = me.baseNode.getNode("green["~me.posLine~"]",1);
     var blueNode  = me.baseNode.getNode("blue["~me.posLine~"]",1);
     redNode.setValue(red);
     greenNode.setValue(green);
     blueNode.setValue(blue);
     lineNode.setValue(text);
     if (me.posLine < me.maxLines) {
       me.posLine = me.posLine+1;
     }
   },

   #
   # simply replace the text at a particular line
   #
   textAt : func(index, text) {
     var lineNode = me.baseNode.getNode("line["~index~"]",1);
     lineNode.setValue(text);
     me.posLine = index;
   },

   #
   # clears out all the lines and resets the pointer
   #
   clear : func() {
     for(var p = 0; p != me.maxLines; p=p+1) {
          var lineNode = me.baseNode.getNode("line["~p~"]",1);
          lineNode.setValue("");
     }
     me.posLine = 0;
   },

   #
   # call reset when you are done writing to the region
   # it will reset the pointer so next frame you start writing from the top again
   #
   reset : func() {
     for(var p = me.posLine; p != me.maxLines; p=p+1) {
       var lineNode = me.baseNode.getNode("line["~p~"]",1);
       lineNode.setValue("");
     }
     me.posLine = 0;
   }
}