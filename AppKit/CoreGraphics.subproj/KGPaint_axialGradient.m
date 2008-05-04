/*------------------------------------------------------------------------
 *
 * Derivative of the OpenVG 1.0.1 Reference Implementation
 * -------------------------------------
 *
 * Copyright (c) 2007 The Khronos Group Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and /or associated documentation files
 * (the "Materials "), to deal in the Materials without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Materials,
 * and to permit persons to whom the Materials are furnished to do so,
 * subject to the following conditions: 
 *
 * The above copyright notice and this permission notice shall be included 
 * in all copies or substantial portions of the Materials. 
 *
 * THE MATERIALS ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE MATERIALS OR
 * THE USE OR OTHER DEALINGS IN THE MATERIALS.
 *
 *-------------------------------------------------------------------*/
#import "KGPaint_axialGradient.h"

@implementation KGPaint_axialGradient

void KGPaintLinearGradient(KGPaint_axialGradient *self,RIfloat *g, RIfloat *rho, RIfloat x, RIfloat y) {
	RI_ASSERT(self);
	Vector2 u = Vector2Subtract(self->m_linearGradientPoint1 , self->m_linearGradientPoint0);
	RIfloat usq = Vector2Dot(u,u);
	if( usq <= 0.0f )
	{	//points are equal, gradient is always 1.0f
		*g = 1.0f;
		*rho = 0.0f;
		return;
	}
	RIfloat oou = 1.0f / usq;

	Vector2 p=Vector2Make(x, y);
	p = Matrix3x3TransformVector2(self->m_surfaceToPaintMatrix, p);
	p = Vector2Subtract(p,self->m_linearGradientPoint0);
	RI_ASSERT(usq >= 0.0f);
	*g = Vector2Dot(p, u) * oou;
	RIfloat dgdx = oou * u.x * self->m_surfaceToPaintMatrix.matrix[0][0] + oou * u.y * self->m_surfaceToPaintMatrix.matrix[1][0];
	RIfloat dgdy = oou * u.x * self->m_surfaceToPaintMatrix.matrix[0][1] + oou * u.y * self->m_surfaceToPaintMatrix.matrix[1][1];
	*rho = (RIfloat)sqrt(dgdx*dgdx + dgdy*dgdy);
	RI_ASSERT(*rho >= 0.0f);
}

static inline VGColor linearGradientColorAt(KGPaint_axialGradient *self,int x,int y){
   VGColor result;
   
   RIfloat g, rho;
   KGPaintLinearGradient(self,&g, &rho, x+0.5f, y+0.5f);
   result = KGPaintColorRamp(self,g, rho);
   RI_ASSERT((result.m_format == VGColor_sRGBA && !self->m_colorRampPremultiplied) || (result.m_format == VGColor_sRGBA_PRE && self->m_colorRampPremultiplied));

   return VGColorPremultiply(result);
}


VGColorInternalFormat KGPaintReadPremultipliedLinearGradientSpan(KGPaint_axialGradient *self,int x,int y,KGRGBAffff *span,int length){
    VGColorInternalFormat result=0;
   int i;
   
   for(i=0;i<length;i++,x++){
    VGColor s=linearGradientColorAt(self,x,y);
    result=s.m_format;
    span[i]=KGRGBAffffFromColor(s);
   }
   return result;
}

-init {
   [super init];
        self->_readRGBAffff=(KGPaintReadSpan_RGBAffff)KGPaintReadPremultipliedLinearGradientSpan;
	self->m_linearGradientPoint0=Vector2Make(0,0);
	self->m_linearGradientPoint1=Vector2Make(1,0);
   return self;
}


@end