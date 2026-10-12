// Cloudflare Worker: secrets and recipient address must be configured in Cloudflare, never in GitHub.
// Required secrets: RESEND_API_KEY, ORDER_TO_EMAIL, FROM_EMAIL, ALLOWED_ORIGIN
const json=(data,status=200,origin='')=>new Response(JSON.stringify(data),{status,headers:{'Content-Type':'application/json','Cache-Control':'no-store',...(origin?{'Access-Control-Allow-Origin':origin,'Vary':'Origin'}:{})}});
const clean=(v,max=300)=>String(v??'').trim().slice(0,max);
const validEmail=(s)=>/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s)&&s.length<=254;
export default {async fetch(request,env){
 const origin=request.headers.get('Origin')||'';
 const allowed=origin===env.ALLOWED_ORIGIN;
 if(request.method==='OPTIONS')return new Response(null,{status:204,headers:{...(allowed?{'Access-Control-Allow-Origin':origin}:{}),'Access-Control-Allow-Methods':'POST, OPTIONS','Access-Control-Allow-Headers':'Content-Type','Access-Control-Max-Age':'86400','Vary':'Origin'}});
 if(!allowed)return json({success:false,message:'Origin not allowed'},403);
 const url=new URL(request.url);
 if(request.method!=='POST'||!['/api/order','/api/contact'].includes(url.pathname))return json({success:false,message:'Not found'},404,origin);
 if(!request.headers.get('Content-Type')?.startsWith('application/json'))return json({success:false,message:'JSON required'},415,origin);
 if(Number(request.headers.get('Content-Length')||0)>12000)return json({success:false,message:'Request too large'},413,origin);
 let body;try{const raw=await request.text();if(raw.length>12000)throw Error();body=JSON.parse(raw)}catch{return json({success:false,message:'Invalid request'},400,origin)}
 // Honeypot field: optional in future form, rejects automated spam submissions.
 if(body.website)return json({success:true},200,origin);
 const name=clean(body.name,100),email=clean(body.email,254),notes=clean(body.notes||body.message,1200),address=clean(body.address,600);
 if(!name||!validEmail(email))return json({success:false,message:'Name and valid email required'},400,origin);
 const isOrder=url.pathname==='/api/order';
 let lines=[],total=0,orderNumber='';
 if(isOrder){
   if(!address||!Array.isArray(body.items)||body.items.length<1||body.items.length>40)return json({success:false,message:'Invalid order'},400,origin);
   orderNumber=clean(body.orderNumber,80);
   for(const item of body.items){const itemName=clean(item.name,140),qty=Number(item.quantity),price=Number(item.usdUnitPrice);if(!itemName||!Number.isInteger(qty)||qty<1||qty>50||!Number.isFinite(price)||price<0||price>10000)return json({success:false,message:'Invalid item'},400,origin);total+=qty*price;lines.push(`${qty} x ${itemName} — $${(qty*price).toFixed(2)} (client-provided estimate)`)}
 }
 // Prices are client supplied; independently verify before accepting payment or fulfillment.
 const subject=isOrder?`MENOCLONE ORDER ${orderNumber}`:'MENOCLONE CONTACT';
 const message=[`Type: ${isOrder?'Order inquiry':'Contact'}`,`Reference: ${orderNumber||'N/A'}`,`Name: ${name}`,`Email: ${email}`,`Address: ${address||'N/A'}`,`Items:`,...lines,`Estimated total: $${total.toFixed(2)} USD (unverified)`,`Notes: ${notes||'None'}`].join('\n');
 if(!env.RESEND_API_KEY||!env.ORDER_TO_EMAIL||!env.FROM_EMAIL)return json({success:false,message:'Email service not configured'},503,origin);
 const r=await fetch('https://api.resend.com/emails',{method:'POST',headers:{Authorization:`Bearer ${env.RESEND_API_KEY}`,'Content-Type':'application/json'},body:JSON.stringify({from:env.FROM_EMAIL,to:[env.ORDER_TO_EMAIL],reply_to:email,subject,text:message})});
 if(!r.ok){console.error('Email delivery provider returned',r.status);return json({success:false,message:'Email delivery unavailable'},502,origin)}
 return json({success:true,orderNumber},200,origin);
 }};
