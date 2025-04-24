---
layout: default
title: "What I've learnt building ML Training Pipelines"
---

# What I've learnt building ML Training Pipelines

Machine learning at scale can be tricky. And if your product's primary use case is driven by ML, you better have a good training pipeline in place. A lot can go wrong building one, but it is not rocket science (cliche!). It can be an iterative building process, whereas a rocket needs to just work on the first go. Over the years of developing ML systems, I've really enjoyed particularly working on training pipelines. They are responsible for bringing to life everything ML is about — a learned system i.e. a model. But it is also so much more. So, I thought I will just do a brain dump on what I think constitutes a great training pipeline.

## What are training pipelines?

Training pipelines are something that companies adopt when they want scale their ML development, and building adhoc models in Jupyter notebooks is not making the cut anymore. The models need storage, versioning, features, experiments etc. and each aspect has to be automated. Then comes the deployment and inference, which is beast altogether and I will not get into that in this post (maybe in some other one 😉).

In this post, I wanted to share the 3 important components for building a robust training pipeline. This might not be evident when you start building one, but will come to you later, once you start adding features. So its better to structure it right from the start.

## Core Components

TLDR; A training pipeline should have 3 layers - Storage, Execution Engine, and Front End Interface.

I always think about the analogies to any web application.

- **Storage** is your database.
- **Execution engine** is your backend server.
- **Front end interface** is the API service that serves the data (such as storage artifacts and status updates) to the user.

Let's talk about them in more detail.

### 1. Storage

Storage is where all the data, model files, experiment configs and other artifacts are stored. A good storage design lays the foundation for model experiments, so ML engineers can focus more on model performance rather than optimising and figuring out the right storage structure.

The word pipeline in "ML pipeline" means that there will surely be something that the pipe emits, and this is what storage is for. Sorry bad joke 🙈, but you get the point! The exact service to use for storage depends on your cloud service. For example, if you are using AWS, you could use S3. If you are using GCP, you could use Google Cloud Storage. The important aspect is designing a good structure that is flexible for experiments (because ML requires lots of experiments before you get one right).

If the storage is not designed well, things might get messy later. The folder structure gets so deeply baked into the pipeline that it becomes a nightmare to change anything. Some key aspects when designing the folder structure are:

- **accessibility:** it should be easy to find stuff. Imagine digging through folders just to find the best model you trained. In an ideal world, you should not be navigating these folders at all. Your front end interface should surface the links to the datasets & models, but still it does not mean designing a bad system. As Steve Jobs famously said "Design is not just what it looks like and feels like. Design is how it works", and so it is important for the storage to be simple and accessible to just work. The API interface should be like a SQL for your storage. In a traditional DB, we don't scroll rows to find something, we just query it. Similarly the training pipeline should enable searching for stuff via APIs.
- **versioning:** experiments require versions. Your first run will never be successful, but maybe your subsequent runs never perform better. You need to be able to go back to the previous versions of the model and use that. Add versions at all stages wherever you feel there is a need to experiment.
- **minimum duplication:** When thinking about the above 2 points, it is easy to just duplicate a lot of stuff common between experiment runs. Remember that ML always relies on huge datasets, and if the data is duplicated across experiments, it is not a good design. You are incurring unnecessary costs due to bad design. I know storage is cheap, but it can come to haunt you later when your storage becomes bloated enough, and you don't know what to delete (or even how to delete it).

### 2. Execution Engine

To simply put — this is the layer that runs the training i.e. trains models. When the training pipeline launches training jobs, the execution engine runs them. This is where the heavy lifting happens. Fundamentally, this should be like a bare minimum EC2 instance (installed with all your dependencies and training scripts), that is running your `model.fit()` function. When you actually get to designing the details, it is not as simple as running `model.fit()` 😄. I'll not dive into using GPUs here, but that is also an extension here.

What functionalities would you want from an ideal execution engine? Some things that are obvious:

- **scalability:** ML jobs are heavy workloads. You need parallelization like running multiple jobs at the same time, running multiple operations in parallel, loading data in parallel, etc. Your system has both CPU and memory. So make sure to use them effectively, and not waste resources. Feeding more data should not break your code.
- **flexibility:** the engine should be flexible with algorithms. Actual implementation of the algorithm happens in this layer. There should be frontend APIs that enable the choice of algorithms, or maybe even run multiple algorithms in parallel.
- **monitoring & logging:** the most ignored aspect of ML pipeline. ML workflows are long running jobs. You don't want to wait for a complete day only to figure out that the column selection in the input was wrong and the model needs retraining. One needs good monitoring in place. If required, even setup automated alerts. The important part is to be able to quickly stop/debug the jobs if something is not right.

[AWS SageMaker](https://aws.amazon.com/sagemaker/) provides some out of the box solutions for this layer, but you can build your own layer with Kubernetes (possibly with use of some tools like [Kubeflow](https://www.kubeflow.org/)). I've primarily used SageMaker, so I cannot say much for other solutions out there. I've also know that some companies use [Airflow](https://airflow.apache.org/) to run these jobs.

### 3. Front End Interface

This is not really a front end in the traditional sense. This layer can be built entirely on command line too, but you need a layer to interact with storage and execution layers. The front end interface has all the APIs that help engineers trigger, stop, monitor, debug and analyze the training jobs. A bulk of the training pipeline is written with the goal of making it easier to interface with the storage and the backend server.

A good front end interface allows an engineer to:

- **start jobs:** trigger training jobs with different configurations. You should have a config where the parameters of the ML experiments are defined, and it should be very easy to just start one. This is very subtle, but the pipeline should be smart enough to know that an experiment with a certain config is already run (or running), and should not trigger a new one. So status management becomes very important for this layer.
- **monitor jobs:** it should be easy to see the status of the job/jobs. You can also setup automated alerts (for something going wrong), so you don't have to constantly monitor. Or maybe setup an alert at the job completion. Whatever suits you, this purpose of this layer is to make the engineer's life easy.
- **post training analysis:** seems like a small thing, but this layer should create automated dashboards/notebooks to analyze the performance of the model. This can either be built within the interface or outside of it, and the links can be made available once the training run is complete.

This layer can be built with tools as simple as [GitHub Actions](https://github.com/features/actions) (which provides orchestration and automation for pipelines), or something more complex like an in-house web app (I would not recommend this when you're just starting out with pipelines). Open source tools like [MLflow](https://mlflow.org/), [TensorBoard](https://www.tensorflow.org/tensorboard), and [Kubeflow Pipelines](https://www.kubeflow.org/docs/components/pipelines/) can also be used to build this layer. The dashboards can be built using tools like [Panel](https://panel.holoviz.org/), [Streamlit](https://streamlit.io/), etc.

## Golden Rule for Training Pipelines: Refactor before adding new features

Now that we've discussed the components, time for some random advice. This is only from my experience, and I do not guarantee that this works for all scenarios.

There are often times in an ML engineer's life (or for that matter any software engineer's life) where one part of your brain is tempted to refactor the whole thing just to support a small new feature because you know it should be easy to add that feature, but it is not. When you have that feeling, I think it is always good to refactor. ML pipelines are foundations on which models are built, and it should be simple to add/delete stuff, and experiment stuff.
I've always found thanking my past self for prioritizing refactoring over adding features. It is so tempting to add just another feature. Also, make sure the refactored output is simpler, otherwise it would be stupid to refactor.

When should you consider refactoring?

- **when you are repeating yourself:** When you run multiple experiments, and you are, for example, copying data for each experiment, it is a good time to refactor your storage layer. This is true for all the layers.
- **when adding new features takes more time than you think it should:** Adding features should be easy. If it is not, it is a good time to refactor. Keep your mind open and always think about making pipelines that stand the test of time, and not only cater to your needs.

Refactoring should always result in a more simpler, flexible, scalable and maintainable system.

## Conclusion

This was just my brain dump of ML pipelines that I've been thinking for some time now. So take it with a pinch of salt. Maybe other use cases require more (or less) components.
But one thing is clear, with ML/AI gulping up more and more industries these days, it is more important than ever that companies spend time building a robust training pipeline. This lays the foundation for good ML products and faster iterations.

I'll conclude with one of famous [Elon's quote](https://x.com/elonmusk/status/1389102532706848768) - "Prototypes are easy, production is hard". This holds true, not only for cars, but for ML models as well.