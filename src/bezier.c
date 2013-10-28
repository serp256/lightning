#ifdef ANDROID
#define GL_GLEXT_PROTOTYPES
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#else 
#ifdef IOS
#include <OpenGLES/ES2/gl.h>
#else
#define GL_GLEXT_PROTOTYPES
#ifdef OSlinux
#include <GL/gl.h>
#else
#include <OpenGL/gl.h>
#endif
#endif
#endif

#include <caml/callback.h>
#include <caml/alloc.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/custom.h>
#include <stdio.h>
#include <stdlib.h>
// #define forn(i,f,t) for(int i=f; i<t; ++i)

//typedef float GLfloat;

struct pt{
	GLfloat x;
	GLfloat y;
};
typedef struct pt Pt;
/*
struct rc{
	Pt lt;
	Pt rt;
	Pt rb;
	Pt lb;
};
typedef struct rc Rc;
*/
static inline Pt add(Pt a,Pt b){
	Pt r;
	r.x = a.x + b.x;
	r.y = a.y + b.y;
	return r;
}

static inline Pt sub(Pt a,Pt b){
	Pt r;
	r.x = a.x - b.x;
	r.y = a.y - b.y;
	return r;
}

static inline Pt mul(Pt a,double k){
	Pt r;
	r.x = a.x * k;
	r.y = a.y * k;
	return r;
}

/* (first point, angle point, last point, step, destination array) */
static inline void bezier(Pt p1, Pt p2, Pt p3, double step, Pt* res, int sz){
	Pt v1,v2;
	v1 = sub(p2,p1);
	v2 = sub(p3,p2);
	double c = step;
	res[0] = p1;
	int i;
	for(i=1; c < 1 && i < sz; ++i, c += step){
		Pt p = add(p1,mul(v1,c));
		Pt v = sub(add(p2,mul(v2,c)),p);
		res[i] = add(p,mul(v,c));
	}
	res[i] = p3;
}

/* distortion vector (first point, last point, angle point)*/
static Pt getDistVector(Pt p1,Pt p2, Pt ps){
	Pt p = mul(add(p1,p2),0.5);
	return sub(ps,p);
}
#define distortionPoint(p1,p2,v) add(mul(add((p1),(p2)),0.5),(v))

// заполнение массива вертексов
//void ppt(p){printf("(%f %f)",(float)p.x,(float)p.y);}
static void makeGrid(Pt a, Pt abS, Pt b, Pt bcS, Pt c, Pt cdS, Pt d, Pt adS, double step, int lineLen, Pt *vert, double vW, double vH, int vertQty){
	// + 1 / 2 for all points
#define p1d2(p) (p).x = ((p).x + 1) / 2 * vW; (p).y = ((p).y + 1) / 2 * vH
	p1d2(a);
	p1d2(abS);
	p1d2(b);
	p1d2(bcS);
	p1d2(c);
	p1d2(cdS);
	p1d2(d);
	p1d2(adS);
//	int vertQty = lineLen * lineLen * 4;
	Pt *bcPts = malloc(sizeof(Pt) * (lineLen + 2));
	Pt *adPts = malloc(sizeof(Pt) * (lineLen + 2));
	/* вектора искажения для линий A-B и C-D*/
	Pt abV = getDistVector(a, b, abS);
	Pt cdV = getDistVector(d, c, cdS);
	/* вертикальные кривые B-C и A-D */
	bezier (b, bcS, c, step, bcPts, lineLen+1);
	bezier (a, adS, d, step, adPts, lineLen+1);
	
	/* массив из горизонталтьных кривых. По нему и будет выстраиваться скелет рисунка */
	/* инициализируем его */
	Pt **lrLines = malloc(sizeof(Pt*) * (lineLen + 2));
	int i;
	for(i=0; i<lineLen+2; ++i)
		lrLines[i] = malloc(sizeof(Pt) * (lineLen + 2));
	/* эти переменные нужны для того сколько процентов кривизны нужно взять откаждой из граничных линий */
	double w = (double) lineLen;
	double l1 = 0;
	double l2 = w;
	for(i=0; i<lineLen+2; ++i){
		double k1 = 1 - (l1/w);
		double k2 = 1 - (l2/w);
		Pt v = add(mul(abV, k1), mul(cdV, k2));
		Pt ps = distortionPoint(adPts[i],bcPts[i],v);
		/* крайние точки берем из уже полученных вертикальных кривых, среднюю вычислили только что */
		bezier(adPts[i],ps,bcPts[i],step,lrLines[i],lineLen+1);
		++l1;
		--l2;
	}
	/* делаем так, что бы центр картинки был в 0,0 */
/*
	double minX = lrLines[0][0].x;
	double minY = lrLines[0][0].y;
	double maxX = minX;
	double maxY = minY;

#define min(a,b) ((a) < (b))? (a): (b)
#define max(a,b) ((a) > (b))? (a): (b)
	for(int i=0; i<=lineLen; ++i)
		for(int j=0; j<=lineLen; ++j){
			minX = min(lrLines[i][j].x, minX);
			minY = min(lrLines[i][j].y, minY);
			maxX = max(lrLines[i][j].x, maxX);
			maxY = max(lrLines[i][j].y, maxY);
		}
#undef min
#undef max
	double dx = (maxX - minX) / 2.0;
	double dy = (maxY - minY) / 2.0;
	for(int i=0; i<lineLen+2; ++i)
		for(int j=0; j<=lineLen; ++j){
			lrLines[i][j].x = lrLines[i][j].x - dx;
			lrLines[i][j].y = lrLines[i][j].y - dy;
		}
*/
	/* собираем из прямых четырехугольники */
	int vPos=0;
	int j;
	for(i=0; i<lineLen+1; ++i){
		for(j=0; j<lineLen; ++j){
			// lb, rb, lt, rt
			vert[vPos] = lrLines[i+1][j];
			++vPos;
			//--
			vert[vPos] = vert[vPos-1];
			++vPos;
			//--
			vert[vPos] = lrLines[i+1][j+1];
			++vPos;
			vert[vPos] = lrLines[i][j];
			++vPos;
			vert[vPos] = lrLines[i][j+1];
			++vPos;
			//--
			vert[vPos] = vert[vPos-1];
			++vPos;
			//--
		}
		if (vPos >= vertQty)
			break;
	}
	/* чистим память */
	for(i=0; i<lineLen; ++i)
		free(lrLines[i]);
	free(lrLines);
	free(bcPts);
	free(adPts);
}

// заполнение массива для текстуры
static void makeTexGrid(Pt *tex, double tX, double tY, double tW, double tH, int lineLen, double step, int ptQty){
	int vPos = 0;
	double x;
	double y = 1 - step;
	for(int i=0; i<lineLen; ++i){
		x = 0;
		for(int j=0; j<lineLen; ++j){
			tex[vPos].x = x * tW + tX;
			tex[vPos].y = y * tH + tY;
			++vPos;
			//--
			tex[vPos] = tex[vPos-1];
			++vPos;
			//--
			tex[vPos].x = (x + step) * tW + tX;
			tex[vPos].y = tex[vPos-1].y;
			++vPos;
			tex[vPos].x = tex[vPos-2].x;
			tex[vPos].y = (y + step) * tH + tY;
			++vPos;
			tex[vPos].x = tex[vPos-2].x;//(x + step) * tW + tX;
			tex[vPos].y = tex[vPos-1].y;//(y + step) * tH + tY;
			++vPos;
			//--
			tex[vPos] = tex[vPos-1];
			++vPos;
			//--
			x += step;
		}
		if (vPos >= ptQty)
			break;
		y -= step;
	}
	tex[vPos] = tex[vPos-1];
	tex[0] = tex[1];
}

static Pt vPtoPt(value vp){
	Pt p;
	p.x = Double_val(Field(vp,0));
	p.y = Double_val(Field(vp,1));
	return p;
}

struct arrays{
	int len;
	GLuint bufferTex;
	GLuint bufferCol;
	GLuint bufferVert;
};
typedef struct arrays Arrays;

void arrays_destructor(value v){
	Arrays *a = Data_custom_val(v);
	glDeleteBuffers(1,&(a -> bufferTex));
	glDeleteBuffers(1,&(a -> bufferCol));
	glDeleteBuffers(1,&(a -> bufferVert));
}

struct custom_operations arrays_ops = {
	"pointer to bezier arrays",
	arrays_destructor,
	custom_compare_default,
	custom_hash_default,
	custom_serialize_default,
	custom_deserialize_default
};

// создание стуркуты хранилища и заполнение массива текстуры
CAMLprim value ml_make_grid_tex(value vLineLen, value texClp, value vStep){
	CAMLparam3(vLineLen,texClp,vStep);

	int llen = Int_val(vLineLen);
	int qty = llen * llen;
	int qtyOfPts = qty * 4;
	int qtyOfNonDrawingP = qty * 2;
	int resQty = qtyOfPts + qtyOfNonDrawingP;
	value res = caml_alloc_custom(&arrays_ops,sizeof(Arrays),0,1);
	Arrays *arr = Data_custom_val(res);
	Pt* tex = malloc(sizeof(Pt) * resQty);
	GLbyte (*colors)[4] = malloc(sizeof(GLbyte[4]) * resQty);
	for(int i=0; i< resQty; ++i){
		colors[i][0] = 1;
		colors[i][1] = 1;
		colors[i][2] = 1;
		colors[i][3] = 1;
	}
	arr -> len  = resQty;
	
	double tX = Double_val(Field(texClp,0));
	double tY = Double_val(Field(texClp,1));
	double tW = Double_val(Field(texClp,2));
	double tH = Double_val(Field(texClp,3));
	double step = Double_val(vStep);

	makeTexGrid(tex, tX, tY, tW, tH, llen, step, resQty);
	
	/* далее идет VBO */
	glGenBuffers(1,&(arr -> bufferTex));
	glBindBuffer(GL_ARRAY_BUFFER, arr -> bufferTex);
	glBufferData(GL_ARRAY_BUFFER,sizeof(Pt) * resQty, tex, GL_STATIC_DRAW);
	glGenBuffers(1,&(arr -> bufferCol));
	glBindBuffer(GL_ARRAY_BUFFER, arr -> bufferCol);
	glBufferData(GL_ARRAY_BUFFER,sizeof(GLbyte[4]) * resQty, colors, GL_STATIC_DRAW);
	glBindBuffer(GL_ARRAY_BUFFER,0);
	glGenBuffers(1,&(arr -> bufferVert));
	
	free(tex);
	free(colors);
	
	CAMLreturn(res);
}

// заполнение массива вертексов в уже созданной струтуре хранилища
CAMLprim value ml_make_grid_vert(value vStruct, value arrPt, value vStep, value vLineLen, value vertSize){
	int llen = Int_val(vLineLen);

	Arrays *arr = Data_custom_val(vStruct);
	Pt *vert = malloc(sizeof(Pt) * arr -> len);
	
	Pt p1;
	p1.x = 1;
	p1.y = 1;

	Pt a   = sub(vPtoPt(Field(arrPt,0)),p1);
	Pt abS = sub(vPtoPt(Field(arrPt,1)),p1);
	Pt b   = sub(vPtoPt(Field(arrPt,2)),p1);
	Pt bcS = sub(vPtoPt(Field(arrPt,3)),p1);
	Pt c   = sub(vPtoPt(Field(arrPt,4)),p1);
	Pt cdS = sub(vPtoPt(Field(arrPt,5)),p1);
	Pt d   = sub(vPtoPt(Field(arrPt,6)),p1);
	Pt daS = sub(vPtoPt(Field(arrPt,7)),p1);

	double w = Double_val(Field(vertSize,0));
	double h = Double_val(Field(vertSize,1));

	makeGrid(a,abS,b,bcS,c,cdS,d,daS,Double_val(vStep),llen,vert,w,h,arr -> len);
	/* опять VBO */
	glBindBuffer(GL_ARRAY_BUFFER, arr -> bufferVert);
	glBufferData(GL_ARRAY_BUFFER, sizeof(Pt) * arr -> len, vert, GL_DYNAMIC_DRAW);
	glBindBuffer(GL_ARRAY_BUFFER,0);

	free(vert);

	return Val_unit;
}
