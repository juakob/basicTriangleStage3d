package;

import openfl.Assets;
import openfl.display.Sprite;
import openfl.display3D.Context3DRenderMode;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.Program3D;
import openfl.display3D.textures.Texture;
import openfl.events.ErrorEvent;
import openfl.events.Event;
import openfl.gl.GL;
import openfl.Lib;

/**
 * ...
 * @author Joaquin
 */

class Main extends Sprite 
{

	private var mTileSheetAdvance:TileSheetAdvance;
	public function new() 
	{
		super();
		
		// Assets:
		// openfl.Assets.getBitmapData("img/assetname.jpg");
		addEventListener(Event.ADDED_TO_STAGE, init);
	}
	
	private function init(e:Event):Void 
	{
		removeEventListener(Event.ADDED_TO_STAGE, init);
		stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreate);
		stage.stage3Ds[0].addEventListener(ErrorEvent.ERROR, errorHandler);
		stage.stage3Ds[0].requestContext3D(Context3DRenderMode.AUTO);
		
		
	}
	
	private function errorHandler(e:Event):Void 
	{
		trace("Cant init context");
	}
	
	private function onContext3DCreate(e:Event):Void 
	{
		mTileSheetAdvance = new TileSheetAdvance(stage.stage3Ds[0].context3D);
		addEventListener(Event.ENTER_FRAME, update);
		
		var mTexture:Texture = mTileSheetAdvance.mContext3D.createTexture(400, 400, Context3DTextureFormat.BGRA, false);
		mTexture.uploadFromBitmapData(Assets.getBitmapData("img/openfl.png"));
		
		var mProgram:Program3D = mTileSheetAdvance.mContext3D.createProgram();
		
		var fragmentShaderSource:String = 
			
			#if !desktop
			"precision mediump float;" +
			#end
			"varying vec2 vTexCoord;
			uniform sampler2D uImage0;
			
			void main(void)
			{" + 
			#if ((openfl < "3.0.0") && !openfl_next && !html5)
				"gl_FragColor = texture2D (uImage0, vTexCoord).gbar;" + 
			#else
				"gl_FragColor = texture2D (uImage0, vTexCoord);" + 
			#end
			"}";
			
			var vertexShaderSource:String = 
			
			"attribute vec3 aVertexPosition;
			attribute vec2 aTexCoord;
			varying vec2 vTexCoord;
			
			uniform mat4 uModelViewMatrix;
			uniform mat4 uProjectionMatrix;
			
			void main(void) {
				vTexCoord = aTexCoord;
				gl_Position = uProjectionMatrix * uModelViewMatrix * vec4 (aVertexPosition, 1.0);
			}";
		
		
			var vertexShader = GL.createShader (GL.VERTEX_SHADER);
			GL.shaderSource (vertexShader, vertexShaderSource);
			GL.compileShader (vertexShader);
			
			var fragmentShader = GL.createShader (GL.FRAGMENT_SHADER);
			GL.shaderSource (fragmentShader, fragmentShaderSource);
			GL.compileShader (fragmentShader);
		
			mProgram.upload(vertexShader, fragmentShader);
	}
	
	
	private function update(e:Event):Void 
	{
		
	}
}
