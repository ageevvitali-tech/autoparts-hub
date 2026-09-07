import http from 'node:http';
import {URL} from 'node:url';
import {readFile} from 'node:fs/promises';
import path from 'node:path';

const ROOT = path.resolve('public');
const PORT = Number(process.env.PORT || 10000);
const HOST = process.env.HOST || '0.0.0.0';

const products = [
  {id:'p1', segment:'cars', brand:'Toyota', name:'Масляный фильтр', article:'90915-YZZD2', category:'Фильтры', price:1290, delivery:'1–2 дня', image:'/assets/backgrounds/cars/cars-01.webp', fitment:'Toyota Camry 2018–2024 • 2.5 A25A-FKS', rating:4.9, stock:32},
  {id:'p2', segment:'cars', brand:'Bosch', name:'Тормозные колодки передние', article:'0986494125', category:'Тормозная система', price:3480, delivery:'2–3 дня', image:'/assets/backgrounds/cars/cars-01.webp', fitment:'Toyota Camry / Lexus • проверка по VIN', rating:4.8, stock:18},
  {id:'p3', segment:'cars', brand:'Sachs', name:'Амортизатор передний', article:'314922', category:'Подвеска', price:8290, delivery:'3–5 дней', image:'/assets/backgrounds/cars/cars-01.webp', fitment:'Toyota / VAG — точная применимость по каталогу', rating:4.7, stock:11},
  {id:'p4', segment:'moto', brand:'Honda', name:'Тормозные колодки', article:'06455-MKA-D81', category:'Тормозная система', price:2380, delivery:'1–3 дня', image:'/assets/backgrounds/moto/moto-10.webp', fitment:'Honda CBR / CB — проверка по модели', rating:4.9, stock:14},
  {id:'p5', segment:'moto', brand:'DID', name:'Цепь привода', article:'520VX3-110', category:'Трансмиссия', price:5190, delivery:'2–4 дня', image:'/assets/backgrounds/moto/moto-10.webp', fitment:'Мотоциклы 500–900 cc', rating:4.8, stock:9},
  {id:'p6', segment:'truck', brand:'DAF', name:'Топливный фильтр', article:'1948921', category:'Фильтры', price:6850, delivery:'2–4 дня', image:'/assets/backgrounds/truck/truck-19.webp', fitment:'DAF XF / CF — по VIN', rating:4.8, stock:7},
  {id:'p7', segment:'truck', brand:'WABCO', name:'Тормозной клапан', article:'9730112000', category:'Пневматика', price:12400, delivery:'3–6 дней', image:'/assets/backgrounds/truck/truck-19.webp', fitment:'Грузовые и прицепы — проверка по системе', rating:4.7, stock:5},
  {id:'p8', segment:'trailer', brand:'BPW', name:'Ступичный комплект', article:'S-12010', category:'Ходовая часть', price:18900, delivery:'4–7 дней', image:'/assets/backgrounds/trailer/trailer-28.webp', fitment:'Полуприцепы BPW — по оси и VIN', rating:4.8, stock:4},
  {id:'p9', segment:'bus', brand:'MAN', name:'Фильтр воздушный', article:'81.08405-0024', category:'Фильтры', price:7250, delivery:'2–5 дней', image:'/assets/backgrounds/bus/bus-37.webp', fitment:'MAN Lion’s City — проверка по каталогу', rating:4.6, stock:6},
  {id:'p10', segment:'commercial', brand:'Mercedes-Benz', name:'Фильтр салона', article:'A9068300418', category:'Фильтры', price:2910, delivery:'1–3 дня', image:'/assets/backgrounds/commercial/commercial-46.webp', fitment:'Sprinter — по комплектации', rating:4.8, stock:21},
  {id:'p11', segment:'special', brand:'JCB', name:'Фильтр гидравлики', article:'32/925345', category:'Гидравлика', price:9850, delivery:'3–6 дней', image:'/assets/backgrounds/special/special-55.webp', fitment:'JCB — по модели и серийному номеру', rating:4.7, stock:8},
  {id:'p12', segment:'special', brand:'MTZ', name:'Ремкомплект цилиндра', article:'РК-50-3400', category:'Гидравлика', price:4120, delivery:'2–4 дня', image:'/assets/backgrounds/special/special-55.webp', fitment:'МТЗ — по модели и году выпуска', rating:4.7, stock:13}
];

function json(res, status, body) {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    'Content-Type':'application/json; charset=utf-8',
    'Cache-Control':'no-store',
    'X-Content-Type-Options':'nosniff',
    'X-Frame-Options':'DENY',
    'Referrer-Policy':'strict-origin-when-cross-origin',
    'Permissions-Policy':'camera=(), microphone=(), geolocation=()'
  });
  res.end(payload);
}

async function body(req){
  let data=''; for await (const chunk of req) data += chunk;
  return data ? JSON.parse(data) : {};
}

async function staticFile(res, pathname){
  const decoded = decodeURIComponent(pathname);
  const safe = decoded === '/' ? '/index.html' : decoded;
  const file = path.resolve(ROOT, '.' + safe);
  if (!file.startsWith(ROOT)) return json(res, 403, {error:'forbidden'});
  try {
    const data = await readFile(file);
    const ext = path.extname(file);
    const types = {'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.svg':'image/svg+xml','.json':'application/json','.webp':'image/webp','.png':'image/png','.jpg':'image/jpeg','.jpeg':'image/jpeg','.ico':'image/x-icon'};
    res.writeHead(200, {'Content-Type':types[ext] || 'application/octet-stream', 'Cache-Control':'no-store','X-Content-Type-Options':'nosniff'});
    res.end(data);
  } catch { json(res,404,{error:'not_found'}); }
}

const server = http.createServer(async (req,res)=>{
  try {
    const u = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
    if (u.pathname === '/api/health') return json(res,200,{ok:true,service:'hab-2026',time:new Date().toISOString(),products:products.length});
    if (u.pathname === '/api/catalog' && req.method === 'GET') {
      const q = (u.searchParams.get('q')||'').trim().toLowerCase();
      const segment = (u.searchParams.get('segment')||'').trim();
      const category = (u.searchParams.get('category')||'').trim().toLowerCase();
      let results = products.filter(p => (!segment || p.segment===segment) && (!category || p.category.toLowerCase()===category));
      if (q) results = results.filter(p => `${p.brand} ${p.name} ${p.article} ${p.category} ${p.fitment}`.toLowerCase().includes(q));
      return json(res,200,{results,total:results.length,query:q,segment});
    }
    if (u.pathname === '/api/requests' && req.method === 'POST') {
      const payload = await body(req);
      const id = 'REQ-' + Math.random().toString(36).slice(2,8).toUpperCase();
      return json(res,201,{ok:true,request:{id,status:'received',message:'Запрос принят',payload:{...payload,phone:payload.phone ? '***' : ''}}});
    }
    if (u.pathname === '/api/search-events' && req.method === 'POST') { await body(req); return json(res,202,{ok:true}); }
    if (u.pathname === '/api/ai/assistant' && req.method === 'POST') {
      const p = await body(req); const q = String(p.query||'').toLowerCase();
      const hit = products.find(x => `${x.brand} ${x.name} ${x.article}`.toLowerCase().includes(q));
      return json(res,200,{ok:true,mode:'demo',answer:hit?`Похоже, вы ищете «${hit.name}» ${hit.brand}. Проверьте применимость по VIN перед покупкой.`:'Уточните марку, модель, узел или пришлите фото детали — я предложу кандидатов.',candidates:hit?[hit]:[]});
    }
    return staticFile(res,u.pathname);
  } catch (e) { json(res,500,{error:'server_error',message:e.message}); }
});

server.listen(PORT,HOST,()=>console.log(`HAB-2026 running on http://${HOST}:${PORT}`));
