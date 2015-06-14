package;
import cpp.Void;
import lime.utils.ByteArray;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.textures.TextureBase;
import openfl.display3D.VertexBuffer3D;

/**
 * ...
 * @author Joaquin
 */
class TileSheetAdvance
{
	public var mProgram:Program3D;
	public var mContext3D:Context3D;
	public var mVertexBuffer:VertexBuffer3D;
	public var mIndexBuffer:IndexBuffer3D;
	
	//temp
	private static var numTri:Int = 5000 *2;
	private static var numVertex:Int = numTri * 3;
		
	public var totalTrianglesSentToDraw:Int=0;
	
	public function new(context3D:Context3D) 
	{
		mContext3D = context3D;
		init3D();
	}
	private function init3D():Void 
	{
		//var i:Int
		//for (i < numVertex*4) 
		//{
			//i++;
			//mVertexs.writeFloat(0);
		//}
		
		mVertexBuffer = mContext3D.createVertexBuffer(numVertex, 4);
		
		mVertexBuffer.uploadFromVector(Vertexs.vertexs, 0, (Vertexs.position+1) / 4);
		
		var numIndex:Int = numTri * 3;
		mIndexBuffer = mContext3D.createIndexBuffer(numIndex);
		
		var indexes:ByteArray = new ByteArray(numIndex*4);//number of indexs * 4bytes per Int
		var index:Int = 0;
		var counter:Int = 0;
		while (counter < numIndex) 
		{
			counter += 6;
			indexes.writeInt(index+2, index + 1, index );
			indexes.writeInt(index + 2, index + 1, index + 3);
			index += 4;
		}
		
		mIndexBuffer.uploadFromByteArray(indexes, 0, numIndex);
		
		
		//mProgram = mContext3D.createProgram();
		//
		//mProgram.upload(vertexShaderAssembler.agalcode, fragmentShaderAssembler.agalcode);
		//
			//
	}
	public function clear():Void
	{
		mContext3D.clear(0.5, 0.5, 0.5);
	}
	public function render(aProgram:Program3D, aTexture:TextureBase , aVertexs:ByteArray, offset:Int, startOffset:Int, count:Int):Void
	{
		
		mContext3D.setProgram(aProgram);
		mContext3D.setTextureAt(0, aTexture);
		mContext3D.setGLSLTextureAt(
		mVertexBuffer.uploadFromByteArray(aVertexs, offset,startOffset, count);
		mContext3D.present();
	}
}