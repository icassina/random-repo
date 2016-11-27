import javax.inject.{Inject, Provider, Singleton}

import icassina.lunatech.slick.SlickDAO
import icassina.lunatech.DAO
import icassina.lunatech.DAOExecutionContext
import com.google.inject.AbstractModule
import com.typesafe.config.Config
import play.api.inject.ApplicationLifecycle
import play.api.{Configuration, Environment}

import scala.concurrent.{ExecutionContext, Future}

class Module(environment: Environment,
             configuration: Configuration) extends AbstractModule {
  override def configure(): Unit = {

    bind(classOf[Config]).toInstance(configuration.underlying)
    bind(classOf[DAOExecutionContext]).toProvider(classOf[SlickDAOExecutionContextProvider])

    bind(classOf[slick.jdbc.JdbcBackend.Database]).toProvider(classOf[DatabaseProvider])
    bind(classOf[DAO]).to(classOf[SlickDAO])

    bind(classOf[DAOCloseHook]).asEagerSingleton()
  }
}

@Singleton
class DatabaseProvider @Inject() (config: Config) extends Provider[slick.jdbc.JdbcBackend.Database] {

  private val db = slick.jdbc.JdbcBackend.Database.forConfig("myapp.database", config)

  override def get(): slick.jdbc.JdbcBackend.Database = db
}

@Singleton
class SlickDAOExecutionContextProvider @Inject() (actorSystem: akka.actor.ActorSystem) extends Provider[DAOExecutionContext] {
  private val instance = {
    val ec = actorSystem.dispatchers.lookup("myapp.database-dispatcher")
    new SlickDAOExecutionContext(ec)
  }

  override def get() = instance
}

class SlickDAOExecutionContext(ec: ExecutionContext) extends DAOExecutionContext {
  override def execute(runnable: Runnable): Unit = ec.execute(runnable)

  override def reportFailure(cause: Throwable): Unit = ec.reportFailure(cause)
}

/** Closes database connections safely.  Important on dev restart. */
class DAOCloseHook @Inject()(dao: DAO, lifecycle: ApplicationLifecycle) {
  private val logger = org.slf4j.LoggerFactory.getLogger("application")

  lifecycle.addStopHook { () =>
    Future.successful {
      logger.info("Now closing database connections!")
      dao.close()
    }
  }
}
