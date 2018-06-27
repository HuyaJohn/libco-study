using namespace std;
static void* thread_func(void* arg)
{
    stCoClosure_t* p = (stCoClosure_t*) arg;
    p->exec();
    return 0;
}
static void batch_exec(vector<stCoClosure_t*>& v)
{
    vector<pthread_t> ths;

    for (size_t i=0; i<v.size(); i++)
    {
        pthread_t tid;
        pthread_create(&tid,0,thread_func,v[i]);
        ths.push_back(tid);
    }

    for (size_t i=0; i<v.size(); i++)
    {
        pthread_join(ths[i],0);
    }
}
int main(int argc,char* argv[])
{
    vector< stCoClosure_t* > v;
    pthread_mutex_t m = { { 0, 0, 0, 0, 0, 0, 0, { 0, 0 } } };
    int total = 100;
    vector<int> v2;
    typedef typeof(total) typeof_total;
    typedef typeof(v2) typeof_v2;
    typedef typeof(m) typeof_m;
    class type_ref
    {
    public:
        typeof_total& total;
        typeof_v2& v2;
        typeof_m& m;
        int _member_cnt;
        type_ref(typeof_total& totalr, typeof_v2& v2r, typeof_m& mr, ...): total(totalr), v2(v2r), m(mr), _member_cnt(3) {}
    } ref(total,v2,m) ;;

    for (int i=0; i<10; i++)
    {
        typedef typeof(ref) typeof_ref;
        typedef typeof(i) typeof_i;
        class f:public stCoClosure_t
        {
        public:
            typeof_ref ref;
            typeof_i i;
            int _member_cnt;
        public:
            f(typeof_ref& refr, typeof_i& ir, ...): ref(refr), i(ir), _member_cnt(2) {} void exec()
            {
                printf("ref.total %d i %d\n",ref.total,i);
                pthread_mutex_lock(&ref.m);
                ref.v2.push_back(i);
                pthread_mutex_unlock(&ref.m);
            }
        };
        v.push_back(new f(ref,i));
    }

    for (int i=0; i<2; i++)
    {
        typedef typeof(i) typeof_i;
        class f2:public stCoClosure_t
        {
        public:
            typeof_i i;
            int _member_cnt;
        public:
            f2(typeof_i& ir, ...): i(ir), _member_cnt(1) {} void exec()
            {
                printf("i: %d\n",i);

                for (int j=0; j<2; j++)
                {
                    usleep(1000);
                    printf("i %d j %d\n",i,j);
                }
            }
        };
        v.push_back(new f2(i));
    }

    batch_exec(v);
    printf("done\n");
    return 0;
}
